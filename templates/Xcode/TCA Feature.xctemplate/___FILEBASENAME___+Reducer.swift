import FeaturePrelude

// MARK: - ___VARIABLE_featureName___
public struct ___VARIABLE_featureName___: Sendable, FeatureReducer {
	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .none
		}
	}
}
