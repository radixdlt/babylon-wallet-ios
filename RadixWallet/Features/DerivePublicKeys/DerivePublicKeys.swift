import ComposableArchitecture
import Sargon
import SwiftUI

// MARK: - DerivePublicKeys
public struct DerivePublicKeys: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public enum Purpose: Sendable, Hashable {
			case createNewEntity(kind: EntityKind)
			case accountRecoveryScan
			case importLegacyAccounts
			case createAuthSigningKey(forEntityKind: EntityKind)

			public var loadMnemonicPurpose: SecureStorageClient.LoadMnemonicPurpose {
				switch self {
				case .accountRecoveryScan: .accountRecoveryScan
				case let .createNewEntity(entityKind):
					.createEntity(kind: entityKind)
				case let .createAuthSigningKey(kind):
					.createSignAuthKey(forEntityKind: kind)
				case .importLegacyAccounts:
					.importOlympiaAccounts
				}
			}

			var factorSourceAccessPurpose: FactorSourceAccess.State.Purpose {
				switch self {
				case .createNewEntity(.account):
					.createAccount
				case .createNewEntity(.persona):
					.createPersona
				case .accountRecoveryScan:
					.deriveAccounts
				case .importLegacyAccounts:
					.deriveAccounts
				case .createAuthSigningKey:
					.createKey
				}
			}
		}

		public let derivationsPathOption: DerivationPathOption
		public enum DerivationPathOption: Sendable, Hashable {
			case knownPaths([DerivationPath], networkID: NetworkID) // derivation paths must not be a Set, since import from Olympia can contain duplicate derivation paths, for different Ledger devices.
			case next(networkOption: NetworkOption, entityKind: EntityKind, curve: SLIP10Curve, scheme: DerivationPathScheme)

			public enum NetworkOption: Sendable, Hashable {
				case specific(NetworkID)
				case useCurrent

				public init(networkID: NetworkID?) {
					if let networkID {
						self = .specific(networkID)
					} else {
						self = .useCurrent
					}
				}
			}

			public static func next(
				for entityKind: EntityKind,
				networkID: NetworkID?,
				curve: SLIP10Curve,
				scheme: DerivationPathScheme
			) -> Self {
				.next(
					networkOption: .init(networkID: networkID),
					entityKind: entityKind,
					curve: curve,
					scheme: scheme
				)
			}
		}

		public let factorSourceOption: FactorSourceOption

		public enum FactorSourceOption: Sendable, Hashable {
			case device
			case specific(FactorSource)
			case specificPrivateHDFactorSource(PrivateHierarchicalDeterministicFactorSource)

			var factorSourceAccessKind: FactorSourceAccess.State.Kind {
				switch self {
				case .device:
					.device
				case let .specific(source):
					switch source {
					case .device:
						.device
					case let .ledger(ledger):
						.ledger(ledger)
					default:
						fatalError("Implement")
					}
				case .specificPrivateHDFactorSource:
					.device
				}
			}
		}

		public let purpose: Purpose
		public var factorSourceAccess: FactorSourceAccess.State

		public init(
			derivationPathOption: DerivationPathOption,
			factorSourceOption: FactorSourceOption,
			purpose: Purpose
		) {
			self.derivationsPathOption = derivationPathOption
			self.factorSourceOption = factorSourceOption
			self.purpose = purpose
			self.factorSourceAccess = .init(kind: factorSourceOption.factorSourceAccessKind, purpose: purpose.factorSourceAccessPurpose)
		}
	}

	public enum InternalAction: Sendable, Hashable {
		case start
		case loadedDeviceFactorSource(DeviceFactorSource)
		case deriveWithDeviceFactor(DerivationPath, NetworkID, PublicKeysFromOnDeviceHDRequest.Source)
		case deriveWithLedgerFactor(LedgerHardwareWalletFactorSource, DerivationPath, NetworkID)
	}

	public enum DelegateAction: Sendable, Hashable {
		case derivedPublicKeys(
			[HierarchicalDeterministicPublicKey],
			factorSourceID: FactorSourceID,
			networkID: NetworkID
		)
		case failedToDerivePublicKey
		case cancel
	}

	@CasePathable
	public enum ChildAction: Sendable, Hashable {
		case factorSourceAccess(FactorSourceAccess.Action)
	}

	@Dependency(\.accountsClient) var accountsClient
	@Dependency(\.personasClient) var personasClient
	@Dependency(\.factorSourcesClient) var factorSourcesClient
	@Dependency(\.deviceFactorSourceClient) var deviceFactorSourceClient
	@Dependency(\.ledgerHardwareWalletClient) var ledgerHardwareWalletClient

	public init() {}

	public var body: some ReducerOf<Self> {
		Scope(state: \.factorSourceAccess, action: /Action.child .. ChildAction.factorSourceAccess) {
			FactorSourceAccess()
		}
		Reduce(core)
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case .start:
			switch state.factorSourceOption {
			case .device:
				return .run { send in
					let babylonFactorSource = try await factorSourcesClient.getMainDeviceFactorSource()
					await send(.internal(.loadedDeviceFactorSource(babylonFactorSource)))
				} catch: { error, send in
					loggerGlobal.error("Failed to load factor source, error: \(error)")
					await send(.delegate(.failedToDerivePublicKey))
				}

			case let .specificPrivateHDFactorSource(privateHD):
				return deriveWith(source: .privateHDFactorSource(privateHD), state)

			case let .specific(factorSource):
				switch factorSource {
				case let .device(deviceFactorSource):
					return deriveWith(
						source: .loadMnemonicFor(
							deviceFactorSource,
							purpose: state.purpose.loadMnemonicPurpose
						),
						state
					)
				case let .ledger(ledgerFactorSource):
					return deriveWith(ledgerFactorSource: ledgerFactorSource, state)
				default:
					loggerGlobal.critical("Unsupported factor source: \(factorSource)")
					return .send(.delegate(.failedToDerivePublicKey))
				}
			}

		case let .loadedDeviceFactorSource(factorSource):
			return deriveWith(
				source: .loadMnemonicFor(
					factorSource,
					purpose: state.purpose.loadMnemonicPurpose
				),
				state
			)

		case let .deriveWithDeviceFactor(derivationPath, networkID, source):
			return deriveWith(
				derivationPaths: [derivationPath],
				networkID: networkID,
				source: source,
				state: state
			)

		case let .deriveWithLedgerFactor(ledger, derivationPath, networkID):
			return deriveWith(
				ledger: ledger,
				derivationPaths: [derivationPath],
				networkID: networkID,
				state: state
			)
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case .factorSourceAccess(.delegate(.perform)):
			.send(.internal(.start))
		case .factorSourceAccess(.delegate(.cancel)):
			.send(.delegate(.cancel))
		default:
			.none
		}
	}
}

extension DerivePublicKeys {
	private func deriveWith(
		source: PublicKeysFromOnDeviceHDRequest.Source,
		_ state: State
	) -> Effect<Action> {
		withDerivationPath(
			state: state,
			hdFactorSource: source.deviceFactorSource,
			knownPaths: {
				try await _deriveWith(derivationPaths: $0, networkID: $1, source: source, state: state)
			},
			calculating: {
				.internal(.deriveWithDeviceFactor($0, $1, source))
			}
		)
	}

	private func deriveWith(
		ledgerFactorSource: LedgerHardwareWalletFactorSource,
		_ state: State
	) -> Effect<Action> {
		withDerivationPath(
			state: state,
			hdFactorSource: ledgerFactorSource,
			knownPaths: { path, networkID in
				try await _deriveWith(
					ledger: ledgerFactorSource,
					derivationPaths: path,
					networkID: networkID,
					state: state
				)
			},
			calculating: { path, networkID in .internal(.deriveWithLedgerFactor(ledgerFactorSource, path, networkID)) }
		)
	}

	private func deriveWith(
		derivationPaths: [DerivationPath],
		networkID: NetworkID,
		source: PublicKeysFromOnDeviceHDRequest.Source,
		state: State
	) -> Effect<Action> {
		.run { send in
			try await send(_deriveWith(
				derivationPaths: derivationPaths,
				networkID: networkID,
				source: source,
				state: state
			))
		} catch: { error, send in
			loggerGlobal.error("Failed to derive or cast public key, error: \(error)")
			await send(.delegate(.failedToDerivePublicKey))
		}
	}

	private func _deriveWith(
		derivationPaths: [DerivationPath],
		networkID: NetworkID,
		source: PublicKeysFromOnDeviceHDRequest.Source,
		state: State
	) async throws -> Action {
		loggerGlobal.debug("Starting derivation of #\(derivationPaths.count) keys")
		let hdKeys = try await deviceFactorSourceClient.publicKeysFromOnDeviceHD(.init(derivationPaths: derivationPaths, source: source))
		loggerGlobal.debug("Finish deriving of #\(hdKeys.count) keys ✅ => delegating `derivedPublicKeys`")
		return .delegate(.derivedPublicKeys(
			hdKeys,
			factorSourceID: source.deviceFactorSource.id.asGeneral,
			networkID: networkID
		))
	}

	private func deriveWith(
		ledger: LedgerHardwareWalletFactorSource,
		derivationPaths: [DerivationPath],
		networkID: NetworkID,
		state: State
	) -> Effect<Action> {
		.run { send in
			try await send(_deriveWith(
				ledger: ledger,
				derivationPaths: derivationPaths,
				networkID: networkID,
				state: state
			))
		} catch: { error, send in
			loggerGlobal.error("Failed to derive or cast public key, error: \(error)")
			await send(.delegate(.failedToDerivePublicKey))
		}
	}

	private func _deriveWith(
		ledger: LedgerHardwareWalletFactorSource,
		derivationPaths: [DerivationPath],
		networkID: NetworkID,
		state: State
	) async throws -> Action {
		let hdKeys = try await ledgerHardwareWalletClient.derivePublicKeys(
			derivationPaths.map {
				P2P.LedgerHardwareWallet.KeyParameters(
					curve: $0.curve.p2pCurve,
					derivationPath: $0.toString()
				)
			},
			ledger
		)

		return .delegate(.derivedPublicKeys(
			hdKeys,
			factorSourceID: ledger.id.asGeneral,
			networkID: networkID
		))
	}
}

extension DerivePublicKeys {
	private func withDerivationPath(
		state: State,
		hdFactorSource: some BaseFactorSourceProtocol,
		knownPaths deriveWithKnownDerivationPaths: @escaping @Sendable ([DerivationPath], NetworkID) async throws -> Action,
		calculating calculatedDerivationPath: @escaping @Sendable (DerivationPath, NetworkID) -> Action
	) -> Effect<Action> {
		switch state.derivationsPathOption {
		case let .knownPaths(derivationPaths, networkID):
			return .run { send in
				try await send(deriveWithKnownDerivationPaths(derivationPaths, networkID))
			} catch: { error, send in
				loggerGlobal.error("Failed to create derivation path, error: \(error)")
				await send(.delegate(.failedToDerivePublicKey))
			}
		case let .next(networkOption, entityKind, curve, derivationPathScheme):

			let factorSourceID = hdFactorSource.factorSourceID
			switch networkOption {
			case let .specific(networkID):
				return .run { send in
					let derivationPath = try await nextDerivationPath(
						factorSourceID: factorSourceID,
						of: entityKind,
						derivationPathScheme: derivationPathScheme,
						networkID: networkID
					)
					assert(derivationPath.curve == curve)
					try await send(deriveWithKnownDerivationPaths([derivationPath], networkID))
				} catch: { error, send in
					loggerGlobal.error("Failed to create derivation path, error: \(error)")
					await send(.delegate(.failedToDerivePublicKey))
				}

			case .useCurrent:
				return .run { send in
					let networkID = await factorSourcesClient.getCurrentNetworkID()
					let derivationPath = try await nextDerivationPath(
						factorSourceID: factorSourceID,
						of: entityKind,
						derivationPathScheme: derivationPathScheme,
						networkID: nil
					)
					await send(calculatedDerivationPath(derivationPath, networkID))
				} catch: { error, send in
					loggerGlobal.error("Failed to create derivation path, error: \(error)")
					await send(.delegate(.failedToDerivePublicKey))
				}
			}
		}
	}

	private func nextDerivationPath(
		factorSourceID: FactorSourceID,
		of entityKind: EntityKind,
		derivationPathScheme: DerivationPathScheme,
		networkID maybeNetworkID: NetworkID?
	) async throws -> DerivationPath {
		let (index, networkID) = try await nextIndex(
			factorSourceID: factorSourceID,
			of: entityKind,
			derivationPathScheme: derivationPathScheme,
			networkID: maybeNetworkID
		)
		return try DerivationPath.forEntity(
			kind: entityKind,
			networkID: networkID,
			index: index
		)
	}

	private func nextIndex(
		factorSourceID: FactorSourceID,
		of entityKind: EntityKind,
		derivationPathScheme: DerivationPathScheme,
		networkID maybeNetworkID: NetworkID?
	) async throws -> (index: HDPathValue, networkID: NetworkID) {
		let currentNetwork = await accountsClient.getCurrentNetworkID()
		let networkID = maybeNetworkID ?? currentNetwork
		let request = NextEntityIndexForFactorSourceRequest(
			entityKind: entityKind,
			factorSourceID: factorSourceID,
			derivationPathScheme: derivationPathScheme,
			networkID: networkID
		)
		let index = try await factorSourcesClient.nextEntityIndexForFactorSource(request)
		return (index, networkID)
	}
}

extension SLIP10Curve {
	var p2pCurve: P2P.LedgerHardwareWallet.KeyParameters.Curve {
		switch self {
		case .curve25519:
			.curve25519
		case .secp256k1:
			.secp256k1
		}
	}
}
