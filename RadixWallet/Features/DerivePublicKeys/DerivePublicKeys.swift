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
		case onFirstTask
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
		case .onFirstTask:
			switch state.factorSourceOption {
			case .device:
				return .run { send in
					let babylonFactorSource = try await factorSourcesClient
						.getFactorSources()
						.babylonDeviceFactorSources()
						.first // FIXME: should only have one babylon factor source, which should be in keychain, clean this up.

					await send(.internal(.loadedDeviceFactorSource(babylonFactorSource)))
				} catch: { error, send in
					loggerGlobal.error("Failed to load factor source, error: \(error)")
					await send(.delegate(.failedToDerivePublicKey))
				}

			case let .specific(factorSource):
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
		let hdKeys = try await deviceFactorSourceClient.publicKeysFromOnDeviceHD(.init(
			deviceFactorSource: deviceFactorSource,
			derivationPaths: derivationPaths,
			loadMnemonicPurpose: loadMnemonicPurpose
		))
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
			}
		case let .next(networkOption, entityKind, curve):
			let loadMnemonicPurpose: SecureStorageClient.LoadMnemonicPurpose = switch state.purpose {
			case .createEntity:
				.createEntity(kind: entityKind)
			case .createAuthSigningKey:
				.createSignAuthKey
			case .importLegacyAccounts:
				.importOlympiaAccounts
			}
			switch networkOption {
			case let .specific(networkID):
				return .run { send in
					let derivationPath = try await nextDerivationPath(of: entityKind, networkID: networkID)
					assert(derivationPath.curveForScheme == curve)
					try await send(deriveWithKnownDerivationPaths([derivationPath], networkID, loadMnemonicPurpose))
				}

			case .useCurrent:
				return .run { send in
					let networkID = await factorSourcesClient.getCurrentNetworkID()
					let derivationPath = try await nextDerivationPath(of: entityKind, networkID: nil)
					await send(calculatedDerivationPath(derivationPath, networkID, loadMnemonicPurpose))
				} catch: { error, send in
					loggerGlobal.error("Failed to create derivation path, error: \(error)")
					await send(.delegate(.failedToDerivePublicKey))
				}
			}
		}
	}

	private func nextDerivationPath(
		of entityKind: EntityKind,
		networkID maybeNetworkID: NetworkID?
	) async throws -> DerivationPath {
		let (index, networkID) = try await nextIndex(of: entityKind, networkID: maybeNetworkID)
		return try DerivationPath.forEntity(kind: entityKind, networkID: networkID, index: index)
	}

	private func nextIndex(
		of entityKind: EntityKind,
		networkID maybeNetworkID: NetworkID?
	) async throws -> (index: HD.Path.Component.Child.Value, networkID: NetworkID) {
		let (index, _networkID) = await { () async -> (HD.Path.Component.Child.Value, NetworkID) in
			let currentNetwork = await accountsClient.getCurrentNetworkID()
			let networkID = maybeNetworkID ?? currentNetwork
			switch entityKind {
			case .account:
				return await (accountsClient.nextAccountIndex(networkID), networkID)
			case .identity:
				return await (personasClient.nextPersonaIndex(networkID), networkID)
			}
		}()
		return (index: index, networkID: _networkID)
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
