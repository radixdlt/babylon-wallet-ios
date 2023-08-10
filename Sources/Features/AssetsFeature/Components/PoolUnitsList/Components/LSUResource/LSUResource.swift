import FeaturePrelude

extension PoolUnitsList {
	// MARK: - LSUResource
	public struct LSUResource: Sendable, FeatureReducer {
		public struct State: Sendable, Hashable {
			var isExpanded: Bool = false

			var stakes: IdentifiedArrayOf<LSUDetails.State>
		}

		public enum ViewAction: Sendable, Equatable {
			case isExpandedToggled
		}

		public enum ChildAction: Sendable, Equatable {
			case details(id: LSUDetails.State.ID, action: LSUDetails.Action)
		}

		public var body: some ReducerProtocolOf<Self> {
			Reduce(core)
				.forEach(
					\.stakes,
					action: /Action.child .. ChildAction.details,
					element: LSUDetails.init
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
}
