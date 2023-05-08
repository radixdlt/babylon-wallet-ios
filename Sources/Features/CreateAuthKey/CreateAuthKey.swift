import FeaturePrelude
import ROLAClient
import TransactionReviewFeature

// MARK: - CreateAuthKey
public struct CreateAuthKey: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let entity: EntityPotentiallyVirtual
		public var transactionReview: TransactionReview.State?

		public init(entity: EntityPotentiallyVirtual) {
			self.entity = entity
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
	}

	public enum InternalAction: Sendable, Equatable {
		case createdManifest(TransactionManifest)
	}

	public enum ChildAction: Sendable, Equatable {
		case transactionReview(TransactionReview.Action)
	}

	public enum DelegateAction: Sendable, Equatable {
		case done(success: Bool)
	}

	@Dependency(\.rolaClient) var rolaClient

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
				let manifest = try await rolaClient.manifestForAuthKeyCreation(.init(entity: entity))
				await send(.internal(.createdManifest(manifest)))
			} catch: { _, send in
				loggerGlobal.error("Failed to create manifest for create auth")
				await send(.delegate(.done(success: false)))
			}
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .createdManifest(manifest):
			state.transactionReview = .init(transactionManifest: manifest, message: nil)
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .transactionReview(.delegate(.failed(error))):
			loggerGlobal.error("TX failed, error: \(error)")
			return .send(.delegate(.done(success: false)))
		case let .transactionReview(.delegate(.signedTXAndSubmittedToGateway(txID))):
			loggerGlobal.notice("Successfully signed and submitted CreateAuthKey tx to gateway...txID: \(txID)")
			return .none
		case let .transactionReview(.delegate(.transactionCompleted(txID))):
			loggerGlobal.notice("Successfully CreateAuthKey, txID: \(txID)")
			return .send(.delegate(.done(success: true)))

		case .transactionReview:
			return .none
		}
	}
}
