import FeaturePrelude

// MARK: - LSUResource
public struct LSUResource: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		var isExpanded: Bool = false

		var components: IdentifiedArrayOf<LSUComponent.State> = [
			LSUComponent.State(stake: 0),
			LSUComponent.State(stake: 1),
		]
	}

	public enum ViewAction: Sendable, Equatable {
		case isExpandedToggled
	}

	public enum ChildAction: Sendable, Equatable {
		case component(id: LSUComponent.State.ID, action: LSUComponent.Action)
	}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.forEach(
				\.components,
				action: /Action.child .. ChildAction.component,
				element: LSUComponent.init
			)
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .isExpandedToggled:
			state.isExpanded.toggle()

			return .none
		}
	}
}
