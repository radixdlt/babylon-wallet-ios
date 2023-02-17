import FeaturePrelude

struct VisitHub: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		public init() {}
	}

	enum ViewAction: Sendable, Equatable {
		case visitHubButtonTapped
	}

	enum DelegateAction: Sendable, Equatable {
		case displayHub
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .visitHubButtonTapped:
			return .send(.delegate(.displayHub))
		}
	}
}
