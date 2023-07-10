import AccountsClient
import Cryptography
import DerivePublicKeysFeature
import FactorSourcesClient
import FeaturePrelude
import PersonasClient
import ROLAClient
import TransactionReviewFeature

// MARK: - GetAuthKeyDerivationPath
public struct GetAuthKeyDerivationPath: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let entity: EntityPotentiallyVirtual
		public init(entity: EntityPotentiallyVirtual) {
			self.entity = entity
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case onFirstTask
	}

	public enum DelegateAction: Sendable, Equatable {
		case failedToFindFactorSource
		case entityAlreadyHasAuthenticationSigningKey
		case gotDerivationPath(DerivationPath, FactorSource)
	}

	public struct View: SwiftUI.View {
		public let store: StoreOf<GetAuthKeyDerivationPath>
		public var body: some SwiftUI.View {
			VStack {
				Color.white
			}
			.onFirstTask { @MainActor in
				ViewStore(store.stateless).send(.view(.onFirstTask))
			}
		}
	}

	@Dependency(\.factorSourcesClient) var factorSourcesClient

	public init() {}
	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .onFirstTask:

			return .run { [entity = state.entity] send in

				let factorSourceID: FactorSourceID
				let authSignDerivationPath: DerivationPath
				let unsecuredEntityControl: UnsecuredEntityControl

				switch entity.securityState {
				case let .unsecured(unsecuredEntityControl_):
					unsecuredEntityControl = unsecuredEntityControl_
					guard unsecuredEntityControl.authenticationSigning == nil else {
						loggerGlobal.notice("Entity: \(entity) already has an authenticationSigning")
						await send(.delegate(.entityAlreadyHasAuthenticationSigningKey))
						return
					}

					loggerGlobal.notice("Entity: \(entity) is about to create an authenticationSigning, publicKey of transactionSigning factor instance: \(unsecuredEntityControl.transactionSigning.publicKey)")
					factorSourceID = unsecuredEntityControl.transactionSigning.factorSourceID.embed()
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
					loggerGlobal.error("Failed to find factor source with ID: \(factorSourceID)")
					await send(.delegate(.failedToFindFactorSource))
					return
				}

				await send(.delegate(.gotDerivationPath(
					authSignDerivationPath,
					factorSource
				)))
			}
		}
	}
}

// MARK: - CreateAuthKey
public struct CreateAuthKey: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let entity: EntityPotentiallyVirtual

		public enum Step: Sendable, Hashable {
			case getAuthKeyDerivationPath(GetAuthKeyDerivationPath.State)
			case derivePublicKeys(DerivePublicKeys.State)
			case transactionReview(TransactionReview.State)
		}

		public var step: Step

		public var authenticationSigningFactorInstance: HierarchicalDeterministicFactorInstance?

		public init(
			entity: EntityPotentiallyVirtual
		) {
			self.entity = entity
			self.step = .getAuthKeyDerivationPath(.init(entity: entity))
		}
	}

	public enum InternalAction: Sendable, Equatable {
		case createdManifestForAuthKeyCreation(TransactionManifest, HierarchicalDeterministicFactorInstance)
		case finishedSettingFactorInstance
	}

	public enum ChildAction: Sendable, Equatable {
		case getAuthKeyDerivationPath(GetAuthKeyDerivationPath.Action)
		case derivePublicKeys(DerivePublicKeys.Action)
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
		Scope(state: \.step, action: /.self) {
			Scope(
				state: /State.Step.getAuthKeyDerivationPath,
				action: /Action.child .. ChildAction.getAuthKeyDerivationPath
			) {
				GetAuthKeyDerivationPath()
			}
			Scope(
				state: /State.Step.derivePublicKeys,
				action: /Action.child .. ChildAction.derivePublicKeys
			) {
				DerivePublicKeys()
			}
			Scope(
				state: /State.Step.transactionReview,
				action: /Action.child .. ChildAction.transactionReview
			) {
				TransactionReview()
			}
		}

		Reduce(core)
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .createdManifestForAuthKeyCreation(manifest, authenticationSigningFactorInstance):
			state.step = .transactionReview(.init(
				transactionManifest: manifest,
                                nonce: .secureRandom(),
				signTransactionPurpose: .internalManifest(.uploadAuthKey),
				message: nil
			))
			state.authenticationSigningFactorInstance = authenticationSigningFactorInstance
			return .none

		case .finishedSettingFactorInstance:
			return .send(.delegate(.done(success: true)))
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case .getAuthKeyDerivationPath(.delegate(.failedToFindFactorSource)):
			return .send(.delegate(.done(success: false)))

		case .getAuthKeyDerivationPath(.delegate(.entityAlreadyHasAuthenticationSigningKey)):
			return .send(.delegate(.done(success: false)))

		case let .getAuthKeyDerivationPath(.delegate(.gotDerivationPath(derivationPath, factorSource))):
			state.step = .derivePublicKeys(.init(
				derivationPathOption: .knownPaths([derivationPath], networkID: state.entity.networkID),
				factorSourceOption: .specific(factorSource),
				purpose: .createAuthSigningKey
			))
			return .none

		case let .derivePublicKeys(.delegate(.derivedPublicKeys(hdKeys, factorSourceID, _))):
			guard let hdKey = hdKeys.first else {
				loggerGlobal.error("Failed to create auth key one single key, got: \(hdKeys.count)")
				return .send(.delegate(.done(success: false)))
			}
			return .run { [entity = state.entity] send in
				let manifest = try await rolaClient.manifestForAuthKeyCreation(.init(entity: entity, newPublicKey: hdKey.publicKey))

				let authenticationSigningFactorInstance = try HierarchicalDeterministicFactorInstance(
					factorSourceID: factorSourceID,
					publicKey: hdKey.publicKey,
					derivationPath: hdKey.derivationPath
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
