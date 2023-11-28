import ComposableArchitecture
import SwiftUI

// MARK: - DerivePublicKeys
public struct DerivePublicKeys: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public enum Purpose: Sendable, Hashable {
			case createEntity(kind: EntityKind)
			case importLegacyAccounts
			case createAuthSigningKey
		}

		public let derivationsPathOption: DerivationPathOption
		public var ledgerBeingUsed: LedgerHardwareWalletFactorSource?
		public enum DerivationPathOption: Sendable, Hashable {
			case knownPaths([DerivationPath], networkID: NetworkID) // derivation paths must not be a Set, since import from Olympia can contain duplicate derivation paths, for different Ledger devices.
			case next(networkOption: NetworkOption, entityKind: EntityKind, curve: SLIP10.Curve)

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
				curve: SLIP10.Curve
			) -> Self {
				.next(
					networkOption: .init(networkID: networkID),
					entityKind: entityKind,
					curve: curve
				)
			}
		}

		public let factorSourceOption: FactorSourceOption

		public enum FactorSourceOption: Sendable, Hashable {
			case device
			case specific(FactorSource)
		}

		public let purpose: Purpose

		public init(
			derivationPathOption: DerivationPathOption,
			factorSourceOption: FactorSourceOption,
			purpose: Purpose
		) {
			self.derivationsPathOption = derivationPathOption
			self.factorSourceOption = factorSourceOption
			self.purpose = purpose
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case onFirstAppear
	}

	public enum InternalAction: Sendable, Hashable {
		case loadedDeviceFactorSource(DeviceFactorSource)
		case deriveWithDeviceFactor(DeviceFactorSource, DerivationPath, NetworkID, SecureStorageClient.LoadMnemonicPurpose)
		case deriveWithLedgerFactor(LedgerHardwareWalletFactorSource, DerivationPath, NetworkID)
	}

	public enum DelegateAction: Sendable, Hashable {
		case derivedPublicKeys(
			[HierarchicalDeterministicPublicKey],
			factorSourceID: FactorSourceID,
			networkID: NetworkID
		)
		case failedToDerivePublicKey
	}

	@Dependency(\.accountsClient) var accountsClient
	@Dependency(\.personasClient) var personasClient
	@Dependency(\.factorSourcesClient) var factorSourcesClient
	@Dependency(\.deviceFactorSourceClient) var deviceFactorSourceClient
	@Dependency(\.ledgerHardwareWalletClient) var ledgerHardwareWalletClient

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .onFirstAppear:
			loggerGlobal.debug("DerivePublicKeys onFirstAppear")
			switch state.factorSourceOption {
			case .device:
				loggerGlobal.debug("Using `device` factor source to derive public keys.")
				return .run { send in
					loggerGlobal.debug("Loading main BDFS...")
					let babylonFactorSource = try await factorSourcesClient.getMainDeviceFactorSource()
					loggerGlobal.debug("Loaded main BDFS ✓")
					await send(.internal(.loadedDeviceFactorSource(babylonFactorSource)))
				} catch: { error, send in
					loggerGlobal.error("Failed to load factor source, error: \(error)")
					await send(.delegate(.failedToDerivePublicKey))
				}

			case let .specific(factorSource):
				loggerGlobal.debug("Using specific factor source to derive public keys - kind: \(factorSource.kind)")
				switch factorSource {
				case let .device(deviceFactorSource):
					return deriveWith(deviceFactorSource: deviceFactorSource, state)
				case let .ledger(ledgerFactorSource):
					state.ledgerBeingUsed = ledgerFactorSource
					return deriveWith(ledgerFactorSource: ledgerFactorSource, state)
				default:
					loggerGlobal.critical("Unsupported factor source: \(factorSource)")
					return .send(.delegate(.failedToDerivePublicKey))
				}
			}
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .loadedDeviceFactorSource(factorSource):
			return deriveWith(deviceFactorSource: factorSource, state)

		case let .deriveWithDeviceFactor(device, derivationPath, networkID, loadMnemonicPurpose):
			loggerGlobal.debug("Deriving using device factor source...id \(device.id)")
			return deriveWith(deviceFactorSource: device, derivationPaths: [derivationPath], networkID: networkID, loadMnemonicPurpose: loadMnemonicPurpose, state: state)

		case let .deriveWithLedgerFactor(ledger, derivationPath, networkID):
			state.ledgerBeingUsed = ledger
			return deriveWith(ledger: ledger, derivationPaths: [derivationPath], networkID: networkID, state: state)
		}
	}
}

extension DerivePublicKeys {
	private func deriveWith(
		deviceFactorSource: DeviceFactorSource,
		_ state: State
	) -> Effect<Action> {
		withDerivationPath(
			state: state,
			hdFactorSource: deviceFactorSource,
			knownPaths: {
				try await _deriveWith(
					deviceFactorSource: deviceFactorSource,
					derivationPaths: $0,
					networkID: $1,
					loadMnemonicPurpose: $2,
					state: state
				)
			},
			calculating: { .internal(.deriveWithDeviceFactor(deviceFactorSource, $0, $1, $2)) }
		)
	}

	private func deriveWith(
		ledgerFactorSource: LedgerHardwareWalletFactorSource,
		_ state: State
	) -> Effect<Action> {
		withDerivationPath(
			state: state,
			hdFactorSource: ledgerFactorSource,
			knownPaths: { path, networkID, _ in
				try await _deriveWith(
					ledger: ledgerFactorSource,
					derivationPaths: path,
					networkID: networkID,
					state: state
				)
			},
			calculating: { path, networkID, _ in .internal(.deriveWithLedgerFactor(ledgerFactorSource, path, networkID)) }
		)
	}

	private func deriveWith(
		deviceFactorSource: DeviceFactorSource,
		derivationPaths: [DerivationPath],
		networkID: NetworkID,
		loadMnemonicPurpose: SecureStorageClient.LoadMnemonicPurpose,
		state: State
	) -> Effect<Action> {
		.run { send in
			try await send(_deriveWith(
				deviceFactorSource: deviceFactorSource,
				derivationPaths: derivationPaths,
				networkID: networkID,
				loadMnemonicPurpose: loadMnemonicPurpose,
				state: state
			))
		} catch: { error, send in
			loggerGlobal.error("Failed to derive or cast public key, error: \(error)")
			await send(.delegate(.failedToDerivePublicKey))
		}
	}

	private func _deriveWith(
		deviceFactorSource: DeviceFactorSource,
		derivationPaths: [DerivationPath],
		networkID: NetworkID,
		loadMnemonicPurpose: SecureStorageClient.LoadMnemonicPurpose,
		state: State
	) async throws -> Action {
		loggerGlobal.debug("Starting derivation of #\(derivationPaths.count) keys")
		let hdKeys = try await deviceFactorSourceClient.publicKeysFromOnDeviceHD(.init(
			deviceFactorSource: deviceFactorSource,
			derivationPaths: derivationPaths,
			loadMnemonicPurpose: loadMnemonicPurpose
		))
		loggerGlobal.debug("Finish deriving of #\(hdKeys.count) keys ✅ => delegating `derivedPublicKeys`")
		return .delegate(.derivedPublicKeys(
			hdKeys,
			factorSourceID: deviceFactorSource.id.embed(),
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
					curve: $0.curveForScheme.p2pCurve,
					derivationPath: $0.path
				)
			},
			ledger
		)

		return .delegate(.derivedPublicKeys(
			hdKeys,
			factorSourceID: ledger.id.embed(),
			networkID: networkID
		))
	}
}

extension DerivePublicKeys {
	private func withDerivationPath(
		state: State,
		hdFactorSource: some HDFactorSourceProtocol,
		knownPaths deriveWithKnownDerivationPaths: @escaping @Sendable ([DerivationPath], NetworkID, SecureStorageClient.LoadMnemonicPurpose) async throws -> Action,
		calculating calculatedDerivationPath: @escaping @Sendable (DerivationPath, NetworkID, SecureStorageClient.LoadMnemonicPurpose) -> Action
	) -> Effect<Action> {
		switch state.derivationsPathOption {
		case let .knownPaths(derivationPaths, networkID):
			loggerGlobal.debug("Deriving public keys at paths: \(derivationPaths)")
			let loadMnemonicPurpose: SecureStorageClient.LoadMnemonicPurpose = switch state.purpose {
			case let .createEntity(kind: entityKind):
				.createEntity(kind: entityKind)
			case .createAuthSigningKey:
				.createSignAuthKey
			case .importLegacyAccounts:
				.importOlympiaAccounts
			}
			return .run { send in
				try await send(deriveWithKnownDerivationPaths(derivationPaths, networkID, loadMnemonicPurpose))
			} catch: { error, send in
				loggerGlobal.error("Failed to create derivation path, error: \(error)")
				await send(.delegate(.failedToDerivePublicKey))
			}
		case let .next(networkOption, entityKind, curve):
			loggerGlobal.debug("Deriving public keys for next entity - kind: \(entityKind)")
			let loadMnemonicPurpose: SecureStorageClient.LoadMnemonicPurpose = switch state.purpose {
			case .createEntity:
				.createEntity(kind: entityKind)
			case .createAuthSigningKey:
				.createSignAuthKey
			case .importLegacyAccounts:
				.importOlympiaAccounts
			}
			let factorSourceID = hdFactorSource.factorSourceID
			switch networkOption {
			case let .specific(networkID):
				return .run { send in
					let derivationPath = try await nextDerivationPath(
						factorSourceID: factorSourceID,
						of: entityKind,
						networkID: networkID
					)
					assert(derivationPath.curveForScheme == curve)
					try await send(deriveWithKnownDerivationPaths([derivationPath], networkID, loadMnemonicPurpose))
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
						networkID: nil
					)
					await send(calculatedDerivationPath(derivationPath, networkID, loadMnemonicPurpose))
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
		networkID maybeNetworkID: NetworkID?
	) async throws -> DerivationPath {
		let (index, networkID) = try await nextIndex(
			factorSourceID: factorSourceID,
			of: entityKind,
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
		networkID maybeNetworkID: NetworkID?
	) async throws -> (index: HD.Path.Component.Child.Value, networkID: NetworkID) {
		let currentNetwork = await accountsClient.getCurrentNetworkID()
		let networkID = maybeNetworkID ?? currentNetwork
		let request = NextEntityIndexForFactorSourceRequest(
			entityKind: entityKind,
			factorSourceID: factorSourceID,
			networkID: networkID
		)
		let index = try await factorSourcesClient.nextEntityIndexForFactorSource(request)
		return (index, networkID)
	}
}

extension SLIP10.Curve {
	var p2pCurve: P2P.LedgerHardwareWallet.KeyParameters.Curve {
		switch self {
		case .curve25519:
			.curve25519
		case .secp256k1:
			.secp256k1
		}
	}
}
