import FeaturePrelude
import TransactionClient

// MARK: - TransactionSigningPrepare
public struct TransactionSigningPrepare: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let rawTransactionManifest: TransactionManifest
		public init(
			rawTransactionManifest: TransactionManifest
		) {
			self.rawTransactionManifest = rawTransactionManifest
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
	}

	public enum DelegateAction: Sendable, Equatable {
		case failedToGetTransactionPreview
		case preparedTransactionToReview(TransactionToReview)
	}

	@Dependency(\.transactionClient) var transactionClient
	@Dependency(\.errorQueue) var errorQueue

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .run { [manifest = state.rawTransactionManifest] send in
				let toReview = try await transactionClient.getTransactionReview(.init(message: "Hey", manifestToSign: manifest))
				await send(.delegate(.preparedTransactionToReview(toReview)))
			} catch: { error, send in
				errorQueue.schedule(error)
				await send(.delegate(.failedToGetTransactionPreview))
			}
		}
	}
}
