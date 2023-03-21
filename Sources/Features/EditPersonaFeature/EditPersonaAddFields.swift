import FeaturePrelude

public struct EditPersonaAddFields: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {}

	public enum ViewAction: Sendable, Equatable {
		case addButtonTapped
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .addButtonTapped:
			// TODO:
			return .none
		}
	}
}
