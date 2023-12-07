// MARK: - RecoverWalletControlWithBDFSComplete

public struct RecoverWalletControlWithBDFSComplete: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public init() {}
	}

	public enum ViewAction: Sendable, Equatable {
		case continueButtonTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case profileCreatedFromImportedBDFS
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .continueButtonTapped:
			.send(.delegate(.profileCreatedFromImportedBDFS))
		}
	}
}
