import Cryptography
import DeviceFactorSourceClient
import FactorSourcesClient
import FeaturePrelude
import LedgerHardwareWalletClient
import SecureStorageClient

// MARK: - DerivePublicKey
public struct DerivePublicKey: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let derivationPathOption: DerivationPathOption
		public enum DerivationPathOption: Sendable, Hashable {
			case known(DerivationPath, networkID: NetworkID)
			case nextBasedOnFactorSource(networkOption: NetworkOption)

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

			public static func next(networkID: NetworkID?) -> Self {
				.nextBasedOnFactorSource(networkOption: .init(networkID: networkID))
			}
		}

		public let factorSourceOption: FactorSourceOption

		/// In case of `Ledger` this is never used....
		public let loadMnemonicPurpose: SecureStorageClient.LoadMnemonicPurpose

		public let curve: SLIP10.Curve

		public enum FactorSourceOption: Sendable, Hashable {
			case device
			case specific(FactorSource)
		}

		public init(
			derivationPathOption: DerivationPathOption,
			factorSourceOption: FactorSourceOption,
			loadMnemonicPurpose: SecureStorageClient.LoadMnemonicPurpose,
			curve: SLIP10.Curve = .curve25519 // safe to always use `curve25519`?
		) {
			self.derivationPathOption = derivationPathOption
			self.factorSourceOption = factorSourceOption
			self.loadMnemonicPurpose = loadMnemonicPurpose
			self.curve = curve
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case onFirstTask
	}

	public enum InternalAction: Sendable, Hashable {
		case loadedHDOnDeviceFactorSource(HDOnDeviceFactorSource)
		case deriveWithDeviceFactor(HDOnDeviceFactorSource, DerivationPath, NetworkID)
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

		case let .deriveWithDeviceFactor(device, derivationPath, networkID):
			return deriveWith(hdOnDeviceFactorSource: device, derivationPath: derivationPath, networkID: networkID, state: state)

		case let .deriveWithLedgerFactor(ledger, derivationPath, networkID):
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
			known: { deriveWith(hdOnDeviceFactorSource: hdOnDeviceFactorSource, derivationPath: $0, networkID: $1, state: state) },
			calculating: { .internal(.deriveWithDeviceFactor(hdOnDeviceFactorSource, $0, $1)) }
		)
	}

	private func deriveWith(ledgerFactorSource: LedgerFactorSource, _ state: State) -> EffectTask<Action> {
		withDerivationPath(
			state: state,
			entityCreatingFactorSource: ledgerFactorSource,
			known: { deriveWith(ledger: ledgerFactorSource, derivationPath: $0, networkID: $1, state: state) },
			calculating: { .internal(.deriveWithLedgerFactor(ledgerFactorSource, $0, $1)) }
		)
	}

	private func deriveWith(
		hdOnDeviceFactorSource: HDOnDeviceFactorSource,
		derivationPath: DerivationPath,
		networkID: NetworkID,
		state: State
	) -> EffectTask<Action> {
		.run { [loadMnemonicPurpose = state.loadMnemonicPurpose, curve = state.curve] send in
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
		fatalError()
	}
}

extension DerivePublicKey {
	private func withDerivationPath<Source: _EntityCreatingFactorSourceProtocol & Sendable>(
		state: State,
		entityCreatingFactorSource: Source,
		known deriveWithKnownDerivationPath: (DerivationPath, NetworkID) -> EffectTask<Action>,
		calculating calculatedDerivationPath: @escaping @Sendable (DerivationPath, NetworkID) -> Action
	) -> EffectTask<Action> {
		switch state.derivationPathOption {
		case let .known(derivationPath, networkID):
			return deriveWithKnownDerivationPath(derivationPath, networkID)
		case let .nextBasedOnFactorSource(networkOption):
			switch networkOption {
			case let .specific(networkID):
				do {
					let derivationPath = try entityCreatingFactorSource.derivationPathForNextEntity(kind: .account, networkID: networkID)
					return deriveWithKnownDerivationPath(derivationPath, networkID)
				} catch {
					loggerGlobal.error("Failed to create derivation path, error: \(error)")
					return .send(.delegate(.failedToDerivePublicKey))
				}
			case .useCurrent:
				return .run { send in
					let networkID = await factorSourcesClient.getCurrentNetworkID()
					let derivationPath = try entityCreatingFactorSource.derivationPathForNextEntity(kind: .account, networkID: networkID)
					await send(calculatedDerivationPath(derivationPath, networkID))
				} catch: { error, send in
					loggerGlobal.error("Failed to create derivation path, error: \(error)")
					await send(.delegate(.failedToDerivePublicKey))
				}
			}
		}
	}
}

/*
 // FIXME: Delete this when we have Multifactor support
 private func sendDerivePublicKeyRequest(
     _ ledger: FactorSource,
     state: State
 ) -> EffectTask<Action> {
     let entityKind = Entity.entityKind

     let request: CreateVirtualEntityRequest

     do {
         request = try CreateVirtualEntityRequest(
             networkID: state.networkID,
             ledger: ledger,
             displayName: state.name,
             extraProperties: { numberOfEntities in
                 switch entityKind {
                 case .identity: return .forPersona(.init(fields: []))
                 case .account: return .forAccount(.init(numberOfAccountsOnNetwork: numberOfEntities))
                 }
             },
             derivePublicKey: { derivationPath in

             }
         )
     } catch {
         loggerGlobal.error("Failed to create CreateVirtualEntityRequest, error: \(error)")
         return .none
     }

     return .run { send in
         await send(.internal(
             .createEntityResult(
                 TaskResult {
                     switch entityKind {
                     case .account:
                         let account = try await accountsClient.newUnsavedVirtualAccountControlledByLedgerFactorSource(request)
                         try await accountsClient.saveVirtualAccount(.init(
                             account: account,
                             shouldUpdateFactorSourceNextDerivationIndex: true
                         ))
                         return try account.cast()
                     case .identity:
                         let persona = try await personasClient.newUnsavedVirtualPersonaControlledByLedgerFactorSource(request)
                         try await personasClient.saveVirtualPersona(persona)
                         return try persona.cast()
                     }
                 }
             )
         ))
     }
 }*/

/*

 extension CreationOfEntity {
     private func createEntityControlledByDeviceFactorSource(
         _ babylonFactorSource: BabylonDeviceFactorSource,
         state: State
     ) -> EffectTask<Action> {
         let entityKind = Entity.entityKind

         let request = CreateVirtualEntityRequest(
             networkID: state.networkID,
             babylonDeviceFactorSource: babylonFactorSource,
             displayName: state.name,
             extraProperties: { numberOfEntities in
                 switch entityKind {
                 case .identity: return .forPersona(.init(fields: []))
                 case .account: return .forAccount(.init(numberOfAccountsOnNetwork: numberOfEntities))
                 }
             }
         )

         return .run { send in
             await send(.internal(.createEntityResult(TaskResult {
                 switch entityKind {
                 case .account:
                     let account = try await accountsClient.newUnsavedVirtualAccountControlledByDeviceFactorSource(request)
                     try await accountsClient.saveVirtualAccount(.init(
                         account: account,
                         shouldUpdateFactorSourceNextDerivationIndex: true
                     ))
                     return try account.cast()
                 case .identity:
                     let persona = try await personasClient.newUnsavedVirtualPersonaControlledByDeviceFactorSource(request)
                     try await personasClient.saveVirtualPersona(persona)
                     return try persona.cast()
                 }
             }
             )))
         }
     }

 }
 */
