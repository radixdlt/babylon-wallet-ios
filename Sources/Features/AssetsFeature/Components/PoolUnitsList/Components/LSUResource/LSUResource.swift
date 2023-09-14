import FeaturePrelude

// MARK: - LSUResource
public struct LSUResource: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		var isExpanded: Bool = false

		var stakes: IdentifiedArrayOf<LSUStake.State>
	}

	public enum ViewAction: Sendable, Equatable {
		case isExpandedToggled
	}

	public enum ChildAction: Sendable, Equatable {
		case stake(id: LSUStake.State.ID, action: LSUStake.Action)
	}

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.forEach(
				\.stakes,
				action: /Action.child .. ChildAction.stake,
				element: LSUStake.init
			)
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .isExpandedToggled:
			state.isExpanded.toggle()

			return .none
		}
	}
}
