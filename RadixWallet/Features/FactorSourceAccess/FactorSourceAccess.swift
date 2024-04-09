// MARK: - FactorSourceAccess

public struct FactorSourceAccess: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public init() {}
	}

	public enum ViewAction: Sendable, Equatable {
		case onFirstTask
		case retryButtonTapped
		case closeButtonTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case perform
	}

	public init() {}

	public func reduce(into _: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .onFirstTask, .retryButtonTapped:
			.send(.delegate(.perform))
		case .closeButtonTapped:
			.none
		}
	}
}
