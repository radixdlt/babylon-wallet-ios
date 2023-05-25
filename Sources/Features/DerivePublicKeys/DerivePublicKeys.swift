import Cryptography
import DeviceFactorSourceClient
import FactorSourcesClient
import FeaturePrelude
import LedgerHardwareWalletClient
import SecureStorageClient

// MARK: - DerivePublicKeys
public struct DerivePublicKeys: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public enum Purpose: Sendable, Hashable {
			case createEntity
			case importLegacyAccounts
			case createAuthSigningKey
		}

		public let derivationsPathOption: DerivationPathOption
		public var ledgerBeingUsed: LedgerFactorSource?
		public enum DerivationPathOption: Sendable, Hashable {
			case knownPaths(OrderedSet<DerivationPath>, networkID: NetworkID)
			case nextBasedOnFactorSource(networkOption: NetworkOption, entityKind: EntityKind, curve: SLIP10.Curve)

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
				.nextBasedOnFactorSource(
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
		case loadedHDOnDeviceFactorSource(HDOnDeviceFactorSource)
		case deriveWithDeviceFactor(HDOnDeviceFactorSource, DerivationPath, NetworkID, SecureStorageClient.LoadMnemonicPurpose)
		case deriveWithLedgerFactor(LedgerFactorSource, DerivationPath, NetworkID)
	}

	public enum DelegateAction: Sendable, Hashable {
		case derivedPublicKeys(
			OrderedSet<HierarchicalDeterministicPublicKey>,
			factorSourceID: FactorSourceID,
			networkID: NetworkID
		)
		case failedToDerivePublicKey
	}

	@Dependency(\.factorSourcesClient) var factorSourcesClient
	@Dependency(\.deviceFactorSourceClient) var deviceFactorSourceClient
	@Dependency(\.ledgerHardwareWalletClient) var ledgerHardwareWalletClient

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .onFirstTask:
			switch state.factorSourceOption {
			case .device:
				return .task {
					do {
						let babylonFactorSource = try await factorSourcesClient
							.getFactorSources()
							.babylonDeviceFactorSources()
							.first // FIXME: should only have one babylon factor source, which should be in keychain, clean this up.

						return .internal(.loadedHDOnDeviceFactorSource(babylonFactorSource.hdOnDeviceFactorSource))
					} catch {
						loggerGlobal.error("Failed to load factor source, error: \(error)")
						return .delegate(.failedToDerivePublicKey)
					}
				}

			case let .specific(factorSource):
				if let hdOnDeviceFactorSource = try? HDOnDeviceFactorSource(factorSource: factorSource) {
					return deriveWith(hdOnDeviceFactorSource: hdOnDeviceFactorSource, state)
				} else if let ledgerFactorSource = try? LedgerFactorSource(factorSource: factorSource) {
					state.ledgerBeingUsed = ledgerFactorSource
					return deriveWith(ledgerFactorSource: ledgerFactorSource, state)
				} else {
					loggerGlobal.critical("Unsupported factor source: \(factorSource)")
					return .send(.delegate(.failedToDerivePublicKey))
				}
			}
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .loadedHDOnDeviceFactorSource(factorSource):
			return deriveWith(hdOnDeviceFactorSource: factorSource, state)

		case let .deriveWithDeviceFactor(device, derivationPath, networkID, loadMnemonicPurpose):
			return deriveWith(hdOnDeviceFactorSource: device, derivationPaths: [derivationPath], networkID: networkID, loadMnemonicPurpose: loadMnemonicPurpose, state: state)

		case let .deriveWithLedgerFactor(ledger, derivationPath, networkID):
			state.ledgerBeingUsed = ledger
			return deriveWith(ledger: ledger, derivationPaths: [derivationPath], networkID: networkID, state: state)
		}
	}
}

extension DerivePublicKeys {
	private func deriveWith(
		hdOnDeviceFactorSource: HDOnDeviceFactorSource,
		_ state: State
	) -> EffectTask<Action> {
		withDerivationPath(
			state: state,
			hdFactorSource: hdOnDeviceFactorSource,
			knownPaths: { deriveWith(hdOnDeviceFactorSource: hdOnDeviceFactorSource, derivationPaths: $0, networkID: $1, loadMnemonicPurpose: $2, state: state) },
			calculating: { .internal(.deriveWithDeviceFactor(hdOnDeviceFactorSource, $0, $1, $2)) }
		)
	}

	private func deriveWith(ledgerFactorSource: LedgerFactorSource, _ state: State) -> EffectTask<Action> {
		withDerivationPath(
			state: state,
			hdFactorSource: ledgerFactorSource,
			knownPaths: { path, networkID, _ in deriveWith(ledger: ledgerFactorSource, derivationPaths: path, networkID: networkID, state: state) },
			calculating: { path, networkID, _ in .internal(.deriveWithLedgerFactor(ledgerFactorSource, path, networkID)) }
		)
	}

	private func deriveWith(
		hdOnDeviceFactorSource: HDOnDeviceFactorSource,
		derivationPaths: OrderedSet<DerivationPath>,
		networkID: NetworkID,
		loadMnemonicPurpose: SecureStorageClient.LoadMnemonicPurpose,
		state: State
	) -> EffectTask<Action> {
		.task {
			do {
				let hdKeys = try await deviceFactorSourceClient.publicKeysFromOnDeviceHD(.init(
					hdOnDeviceFactorSource: hdOnDeviceFactorSource,
					derivationPaths: derivationPaths,
					loadMnemonicPurpose: loadMnemonicPurpose
				))
				return .delegate(.derivedPublicKeys(
					hdKeys,
					factorSourceID: hdOnDeviceFactorSource.id,
					networkID: networkID
				))
			} catch {
				loggerGlobal.error("Failed to derive or cast public key, error: \(error)")
				return .delegate(.failedToDerivePublicKey)
			}
		}
	}

	private func deriveWith(
		ledger: LedgerFactorSource,
		derivationPaths: OrderedSet<DerivationPath>,
		networkID: NetworkID,
		state: State
	) -> EffectTask<Action> {
		.task {
			do {
				let hdKeys = try await ledgerHardwareWalletClient.derivePublicKeys(OrderedSet(validating: derivationPaths.map {
					P2P.LedgerHardwareWallet.KeyParameters(curve: $0.curveForScheme.p2pCurve, derivationPath: $0.path)
				}), ledger)

				return .delegate(.derivedPublicKeys(
					hdKeys,
					factorSourceID: ledger.id,
					networkID: networkID
				))
			} catch {
				loggerGlobal.error("Failed to derive or cast public key, error: \(error)")
				return .delegate(.failedToDerivePublicKey)
			}
		}
	}
}

extension DerivePublicKeys {
	private func withDerivationPath<Source: _HDFactorSourceProtocol>(
		state: State,
		hdFactorSource: Source,
		knownPaths deriveWithKnownDerivationPaths: (OrderedSet<DerivationPath>, NetworkID, SecureStorageClient.LoadMnemonicPurpose) -> EffectTask<Action>,
		calculating calculatedDerivationPath: @escaping @Sendable (DerivationPath, NetworkID, SecureStorageClient.LoadMnemonicPurpose) -> Action
	) -> EffectTask<Action> {
		switch state.derivationsPathOption {
		case let .knownPaths(derivationPaths, networkID):
			let loadMnemonicPurpose: SecureStorageClient.LoadMnemonicPurpose = {
				switch state.purpose {
				case .createEntity:
					return .createEntity(kind: .account)
				case .createAuthSigningKey:
					return .createSignAuthKey
				case .importLegacyAccounts:
					return .importOlympiaAccounts
				}
			}()
			return deriveWithKnownDerivationPaths(derivationPaths, networkID, loadMnemonicPurpose)
		case let .nextBasedOnFactorSource(networkOption, entityKind, curve):
			guard let entityCreatingFactorSource = try? EntityCreatingFactorSource(hdFactorSource) else {
				loggerGlobal.critical("Cannot derive public key for next entity with a non EntityCreating FactorSource. Got kind: \(hdFactorSource.kind)")
				return .send(.delegate(.failedToDerivePublicKey))
			}
			let loadMnemonicPurpose: SecureStorageClient.LoadMnemonicPurpose = {
				switch state.purpose {
				case .createEntity:
					return .createEntity(kind: entityKind)
				case .createAuthSigningKey:
					return .createSignAuthKey
				case .importLegacyAccounts:
					return .importOlympiaAccounts
				}
			}()
			switch networkOption {
			case let .specific(networkID):
				do {
					let derivationPath = try entityCreatingFactorSource.derivationPathForNextEntity(kind: entityKind, networkID: networkID)
					assert(derivationPath.curveForScheme == curve)
					return deriveWithKnownDerivationPaths([derivationPath], networkID, loadMnemonicPurpose)
				} catch {
					loggerGlobal.error("Failed to create derivation path, error: \(error)")
					return .send(.delegate(.failedToDerivePublicKey))
				}
			case .useCurrent:
				return .run { send in
					let networkID = await factorSourcesClient.getCurrentNetworkID()
					let derivationPath = try entityCreatingFactorSource.derivationPathForNextEntity(kind: entityKind, networkID: networkID)
					await send(calculatedDerivationPath(derivationPath, networkID, loadMnemonicPurpose))
				} catch: { error, send in
					loggerGlobal.error("Failed to create derivation path, error: \(error)")
					await send(.delegate(.failedToDerivePublicKey))
				}
			}
		}
	}
}

extension SLIP10.Curve {
	var p2pCurve: P2P.LedgerHardwareWallet.KeyParameters.Curve {
		switch self {
		case .curve25519:
			return .curve25519
		case .secp256k1:
			return .secp256k1
		}
	}
}
