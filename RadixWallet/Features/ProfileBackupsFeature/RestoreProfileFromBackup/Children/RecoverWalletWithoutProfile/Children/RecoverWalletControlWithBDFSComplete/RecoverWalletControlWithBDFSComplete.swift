// MARK: - RecoverWalletControlWithBDFSComplete

public struct RecoverWalletControlWithBDFSComplete: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public init() {}
	}

	public enum ViewAction: Sendable, Equatable {
		case continueTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case profileCreatedFromImportedBDFS
	}

	public init() {}

	public func reduce(into _: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .continueTapped:
			.send(.delegate(.profileCreatedFromImportedBDFS))
		}
	}
}
