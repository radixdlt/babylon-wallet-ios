import FeaturePrelude

extension PoolUnitsList {
	// MARK: - LSUComponent
	public struct LSUResource: Sendable, FeatureReducer {
		public struct State: Sendable, Hashable {
			var isExpanded: Bool

			let components: IdentifiedArrayOf<Prelude.Unit>
		}

		public enum ViewAction: Sendable, Equatable {
			case isExpandedToggled
		}

		public init() {}

		public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
			switch viewAction {
			case .isExpandedToggled:
				state.isExpanded.toggle()

				return .none
			}
		}
	}
}
