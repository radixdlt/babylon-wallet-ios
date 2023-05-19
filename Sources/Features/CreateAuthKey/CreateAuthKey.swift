import AccountsClient
import Cryptography
import DerivePublicKeyFeature
import EngineToolkitModels
import FactorSourcesClient
import FeaturePrelude
import PersonasClient
import ROLAClient
import TransactionReviewFeature

// MARK: - CreateAuthKey
public struct CreateAuthKey: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let entity: EntityPotentiallyVirtual

		public var derivePublicKey: DerivePublicKey.State?

		public var transactionReview: TransactionReview.State?
		public var authenticationSigningFactorInstance: HierarchicalDeterministicFactorInstance?

		public init(
			entity: EntityPotentiallyVirtual
		) {
			self.entity = entity
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
	}

	public enum InternalAction: Sendable, Equatable {
		case readyToDerivePublicKey(DerivationPath, factorSource: FactorSource)
		case createdManifestForAuthKeyCreation(TransactionManifest, HierarchicalDeterministicFactorInstance)
		case finishedSettingFactorInstance
	}

	public enum ChildAction: Sendable, Equatable {
		case derivePublicKey(DerivePublicKey.Action)
		case transactionReview(TransactionReview.Action)
	}

	public enum DelegateAction: Sendable, Equatable {
		case done(success: Bool)
	}

	@Dependency(\.rolaClient) var rolaClient
	@Dependency(\.accountsClient) var accountsClient
	@Dependency(\.personasClient) var personasClient
	@Dependency(\.factorSourcesClient) var factorSourcesClient

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(\.transactionReview, action: /Action.child .. ChildAction.transactionReview) {
				TransactionReview()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:

			return .run { [entity = state.entity] send in

				let factorSourceID: FactorSourceID
				let authSignDerivationPath: DerivationPath
				let unsecuredEntityControl: UnsecuredEntityControl

				switch entity.securityState {
				case let .unsecured(unsecuredEntityControl_):
					unsecuredEntityControl = unsecuredEntityControl_
					guard unsecuredEntityControl.authenticationSigning == nil else {
						loggerGlobal.notice("Entity: \(entity) already has an authenticationSigning")
						await send(.delegate(.done(success: false)))
						return
					}

					loggerGlobal.notice("Entity: \(entity) is about to create an authenticationSigning, publicKey of transactionSigning factor instance: \(unsecuredEntityControl.transactionSigning.publicKey)")
					factorSourceID = unsecuredEntityControl.transactionSigning.factorSourceID
					let hdPath = unsecuredEntityControl.transactionSigning.derivationPath
					switch entity {
					case .account:
						authSignDerivationPath = try hdPath.asAccountPath().switching(
							networkID: entity.networkID,
							keyKind: .authenticationSigning
						).wrapAsDerivationPath()
					case .persona:
						authSignDerivationPath = try hdPath.asIdentityPath().switching(
							keyKind: .authenticationSigning
						).wrapAsDerivationPath()
					}
				}

				guard let factorSource = try await factorSourcesClient.getFactorSource(id: factorSourceID) else {
					fatalError()
				}

				await send(.internal(.readyToDerivePublicKey(
					authSignDerivationPath,
					factorSource: factorSource
				)))
			}

//			return .run { [entity = state.entity] send in
//				let response = try await rolaClient.manifestForAuthKeyCreation(.init(entity: entity))
//				await send(.internal(.createdManifestAndAuthKey(response)))
//			} catch: { error, send in
//				loggerGlobal.error("Failed to create manifest for create auth, \(String(describing: error))")
//				await send(.delegate(.done(success: false)))
//			}
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .readyToDerivePublicKey(derivationPath, factorSource):
			state.derivePublicKey = .init(
				derivationPathOption: .known(derivationPath),
				factorSourceOption: .specific(factorSource)
			)
			return .none

		case let .createdManifestForAuthKeyCreation(manifest, authenticationSigningFactorInstance):
			state.transactionReview = .init(
				transactionManifest: manifest,
				signTransactionPurpose: .internalManifest(.uploadAuthKey),
				message: nil
			)
			state.authenticationSigningFactorInstance = authenticationSigningFactorInstance
			return .none

		case .finishedSettingFactorInstance:
			return .send(.delegate(.done(success: true)))
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .derivePublicKey(.delegate(.derivedPublicKey(newPublicKey, derivationPath, factorSourceID, _))):
			state.derivePublicKey = nil

			return .run { [entity = state.entity] send in
				let manifest = try await rolaClient.manifestForAuthKeyCreation(.init(entity: entity, newPublicKey: newPublicKey))

				let authenticationSigningFactorInstance = HierarchicalDeterministicFactorInstance(
					factorSourceID: factorSourceID,
					publicKey: newPublicKey,
					derivationPath: derivationPath
				)

				await send(.internal(.createdManifestForAuthKeyCreation(manifest, authenticationSigningFactorInstance)))
			}

		case let .transactionReview(.delegate(.failed(error))):
			loggerGlobal.error("TX failed, error: \(error)")
			return .send(.delegate(.done(success: false)))
		case let .transactionReview(.delegate(.signedTXAndSubmittedToGateway(txID))):
			loggerGlobal.notice("Successfully signed and submitted CreateAuthKey tx to gateway...txID: \(txID)")
			return .none
		case let .transactionReview(.delegate(.transactionCompleted(txID))):
			loggerGlobal.notice("Successfully CreateAuthKey, txID: \(txID)")
			guard let authenticationSigningFactorInstance = state.authenticationSigningFactorInstance else {
				loggerGlobal.error("Expected authenticationSigningFactorInstance")
				return .send(.delegate(.done(success: false)))
			}

			return .run { [entity = state.entity] send in
				switch entity {
				case var .account(account):
					switch account.securityState {
					case var .unsecured(entityControl):
						assert(entityControl.authenticationSigning == nil)
						entityControl.authenticationSigning = authenticationSigningFactorInstance
						account.securityState = .unsecured(entityControl)
						try await accountsClient.updateAccount(account)
						await send(.internal(.finishedSettingFactorInstance))
					}
				case var .persona(persona):
					switch persona.securityState {
					case var .unsecured(entityControl):
						assert(entityControl.authenticationSigning == nil)
						entityControl.authenticationSigning = authenticationSigningFactorInstance
						persona.securityState = .unsecured(entityControl)
						try await personasClient.updatePersona(persona)
						await send(.internal(.finishedSettingFactorInstance))
					}
				}
			}

		default:
			return .none
		}
	}
}
