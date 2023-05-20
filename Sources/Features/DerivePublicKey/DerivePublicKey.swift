import Cryptography
import DeviceFactorSourceClient
import FactorSourcesClient
import FeaturePrelude
import LedgerHardwareWalletClient
import SecureStorageClient

// MARK: - DerivePublicKey
public struct DerivePublicKey: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public enum Purpose: Sendable, Hashable {
			case createEntity
			case createAuthSigningKey
		}

		public let derivationPathOption: DerivationPathOption
		public var ledgerBeingUsed: LedgerFactorSource?
		public enum DerivationPathOption: Sendable, Hashable {
			case known(DerivationPath, networkID: NetworkID)
			case nextBasedOnFactorSource(networkOption: NetworkOption, entityKind: EntityKind)

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
				networkID: NetworkID?
			) -> Self {
				.nextBasedOnFactorSource(
					networkOption: .init(networkID: networkID),
					entityKind: entityKind
				)
			}
		}

		var purpose: Purpose {
			switch derivationPathOption {
			case .known: return .createAuthSigningKey
			case .nextBasedOnFactorSource: return .createEntity
			}
		}

		public let factorSourceOption: FactorSourceOption

		public let curve: SLIP10.Curve

		public enum FactorSourceOption: Sendable, Hashable {
			case device
			case specific(FactorSource)
		}

		public init(
			derivationPathOption: DerivationPathOption,
			factorSourceOption: FactorSourceOption,
			curve: SLIP10.Curve = .curve25519 // safe to always use `curve25519`?
		) {
			self.derivationPathOption = derivationPathOption
			self.factorSourceOption = factorSourceOption
			self.curve = curve
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
		case derivedPublicKey(
			SLIP10.PublicKey,
			derivationPath: DerivationPath,
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
				return .run { send in

					let babylonFactorSource = try await factorSourcesClient
						.getFactorSources()
						.babylonDeviceFactorSources()
						.first // FIXME: should only have one babylon factor source, which should be in keychain, clean this up.

					await send(.internal(.loadedHDOnDeviceFactorSource(babylonFactorSource.hdOnDeviceFactorSource)))
				} catch: { error, send in
					loggerGlobal.error("Failed to load factor source, error: \(error)")
					await send(.delegate(.failedToDerivePublicKey))
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
			return deriveWith(hdOnDeviceFactorSource: device, derivationPath: derivationPath, networkID: networkID, loadMnemonicPurpose: loadMnemonicPurpose, state: state)

		case let .deriveWithLedgerFactor(ledger, derivationPath, networkID):
			state.ledgerBeingUsed = ledger
			return deriveWith(ledger: ledger, derivationPath: derivationPath, networkID: networkID, state: state)
		}
	}
}

extension DerivePublicKey {
	private func deriveWith(
		hdOnDeviceFactorSource: HDOnDeviceFactorSource,
		_ state: State
	) -> EffectTask<Action> {
		withDerivationPath(
			state: state,
			entityCreatingFactorSource: hdOnDeviceFactorSource,
			known: { deriveWith(hdOnDeviceFactorSource: hdOnDeviceFactorSource, derivationPath: $0, networkID: $1, loadMnemonicPurpose: $2, state: state) },
			calculating: { .internal(.deriveWithDeviceFactor(hdOnDeviceFactorSource, $0, $1, $2)) }
		)
	}

	private func deriveWith(ledgerFactorSource: LedgerFactorSource, _ state: State) -> EffectTask<Action> {
		withDerivationPath(
			state: state,
			entityCreatingFactorSource: ledgerFactorSource,
			known: { path, networkID, _ in deriveWith(ledger: ledgerFactorSource, derivationPath: path, networkID: networkID, state: state) },
			calculating: { path, networkID, _ in .internal(.deriveWithLedgerFactor(ledgerFactorSource, path, networkID)) }
		)
	}

	private func deriveWith(
		hdOnDeviceFactorSource: HDOnDeviceFactorSource,
		derivationPath: DerivationPath,
		networkID: NetworkID,
		loadMnemonicPurpose: SecureStorageClient.LoadMnemonicPurpose,
		state: State
	) -> EffectTask<Action> {
		.run { [curve = state.curve] send in
			let publicKey = try await deviceFactorSourceClient.publicKeyFromOnDeviceHD(.init(
				hdOnDeviceFactorSource: hdOnDeviceFactorSource,
				derivationPath: derivationPath,
				curve: curve,
				loadMnemonicPurpose: loadMnemonicPurpose
			))
			try await send(.delegate(.derivedPublicKey(
				.init(engine: publicKey),
				derivationPath: derivationPath,
				factorSourceID: hdOnDeviceFactorSource.id,
				networkID: networkID
			)))
		} catch: { error, send in
			loggerGlobal.error("Failed to derive or cast public key, error: \(error)")
			await send(.delegate(.failedToDerivePublicKey))
		}
	}

	private func deriveWith(
		ledger: LedgerFactorSource,
		derivationPath: DerivationPath,
		networkID: NetworkID,
		state: State
	) -> EffectTask<Action> {
		.run { send in
			let publicKey = try await ledgerHardwareWalletClient.deriveCurve25519PublicKey(derivationPath, ledger)
			await send(.delegate(.derivedPublicKey(
				.eddsaEd25519(publicKey),
				derivationPath: derivationPath,
				factorSourceID: ledger.id,
				networkID: networkID
			)))
		} catch: { error, send in
			loggerGlobal.error("Failed to derive or cast public key, error: \(error)")
			await send(.delegate(.failedToDerivePublicKey))
		}
	}
}

extension DerivePublicKey {
	private func withDerivationPath<Source: _EntityCreatingFactorSourceProtocol & Sendable>(
		state: State,
		entityCreatingFactorSource: Source,
		known deriveWithKnownDerivationPath: (DerivationPath, NetworkID, SecureStorageClient.LoadMnemonicPurpose) -> EffectTask<Action>,
		calculating calculatedDerivationPath: @escaping @Sendable (DerivationPath, NetworkID, SecureStorageClient.LoadMnemonicPurpose) -> Action
	) -> EffectTask<Action> {
		switch state.derivationPathOption {
		case let .known(derivationPath, networkID):
			return deriveWithKnownDerivationPath(derivationPath, networkID, .createSignAuthKey)
		case let .nextBasedOnFactorSource(networkOption, entityKind):
			let loadMnemonicPurpose: SecureStorageClient.LoadMnemonicPurpose = .createEntity(kind: entityKind)
			switch networkOption {
			case let .specific(networkID):
				do {
					let derivationPath = try entityCreatingFactorSource.derivationPathForNextEntity(kind: entityKind, networkID: networkID)
					return deriveWithKnownDerivationPath(derivationPath, networkID, loadMnemonicPurpose)
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
