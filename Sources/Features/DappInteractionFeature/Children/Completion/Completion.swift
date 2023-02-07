import FeaturePrelude

// MARK: - Completion
struct Completion: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {}

	enum ViewAction: Sendable, Equatable {
		case appeared
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		.none
	}
}
