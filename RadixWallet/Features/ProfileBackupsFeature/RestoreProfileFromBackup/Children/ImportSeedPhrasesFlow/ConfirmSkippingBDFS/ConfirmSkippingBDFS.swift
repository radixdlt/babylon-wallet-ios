// MARK: - ConfirmSkippingBDFS
struct ConfirmSkippingBDFS: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		init() {}
	}

	enum ViewAction: Sendable, Equatable {
		case confirmTapped
		case closeButtonTapped
	}

	enum DelegateAction: Sendable, Equatable {
		case confirmed
		case cancel
	}

	init() {}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .confirmTapped:
			.send(.delegate(.confirmed))
		case .closeButtonTapped:
			.send(.delegate(.cancel))
		}
	}
}
