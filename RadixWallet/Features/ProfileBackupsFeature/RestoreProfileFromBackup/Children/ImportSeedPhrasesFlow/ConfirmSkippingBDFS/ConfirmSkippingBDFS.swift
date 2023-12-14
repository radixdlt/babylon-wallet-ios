// MARK: - ConfirmSkippingBDFS
public struct ConfirmSkippingBDFS: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public init() {}
	}

	public enum ViewAction: Sendable, Equatable {
		case confirmTapped
		case closeButtonTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case confirmed
		case cancel
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .confirmTapped:
			.send(.delegate(.confirmed))
		case .closeButtonTapped:
			.send(.delegate(.cancel))
		}
	}
}
