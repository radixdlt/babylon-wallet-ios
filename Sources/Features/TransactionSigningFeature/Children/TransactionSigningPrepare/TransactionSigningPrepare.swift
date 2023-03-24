import FeaturePrelude

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

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .none
		}
	}
}
