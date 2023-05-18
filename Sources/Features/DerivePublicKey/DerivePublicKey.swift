import Cryptography
import FeaturePrelude

// MARK: - DerivePublicKey
public struct DerivePublicKey: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let derivationPathOption: DerivationPathOption
		public enum DerivationPathOption: Sendable, Hashable {
			case known(DerivationPath)
			case nextBasedOnFactorSource(networkOption: NetworkOption)

			public enum NetworkOption: Sendable, Hashable {
				case specific(NetworkID)
				case useCurrent
			}
		}

//		/// Mutable so that we can add more ledgers in case of `ledgers`
//		public var factorSourceOption: FactorSourceOption
//		public enum FactorSourceOption: Sendable, Hashable {
//			case ledgers(IdentifiedArrayOf<FactorSource>)
//			case ledger(FactorSource)
//			case device(BabylonDeviceFactorSource)
//		}

		public let factorSourceOption: FactorSourceOption
		public enum FactorSourceOption: Sendable, Hashable {
			case anyOf(factorSources: IdentifiedArrayOf<FactorSource>)
			case specific(factorSource: FactorSource)
		}

		public init(
			derivationPathOption: DerivationPathOption,
			factorSourceOption: FactorSourceOption
		) {
			self.derivationPathOption = derivationPathOption
			self.factorSourceOption = factorSourceOption
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
	}

	public enum DelegateAction: Sendable, Hashable {
		case derivedPublicKey(
			SLIP10.PublicKey,
			derivationPath: DerivationPath,
			factorSourceID: FactorSourceID
		)
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .none
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
                 try await ledgerHardwareWalletClient.deriveCurve25519PublicKey(derivationPath, ledger)
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
