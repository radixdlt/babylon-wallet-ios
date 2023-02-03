import FeaturePrelude

// MARK: - Permission
public struct Permission: Sendable, FeatureReducer {
	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .none
		}
	}
}
