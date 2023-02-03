import FeaturePrelude

// MARK: - Permission
struct Permission: Sendable, FeatureReducer {
	func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .none
		}
	}
}
