import FeaturePrelude
import TransactionClient

// MARK: - TransactionSigningPrepare
public struct TransactionSigningPrepare: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let messageFromDapp: String?
		public let rawTransactionManifest: TransactionManifest
		public init(
			messageFromDapp: String?,
			rawTransactionManifest: TransactionManifest
		) {
			self.messageFromDapp = messageFromDapp
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
			return .run { [msg = state.messageFromDapp, manifest = state.rawTransactionManifest] send in
				let toReview = try await transactionClient.getTransactionReview(.init(message: msg, manifestToSign: manifest))
				await send(.delegate(.preparedTransactionToReview(toReview)))
			} catch: { error, send in
				errorQueue.schedule(error)
				await send(.delegate(.failedToGetTransactionPreview))
			}
		}
	}
}
