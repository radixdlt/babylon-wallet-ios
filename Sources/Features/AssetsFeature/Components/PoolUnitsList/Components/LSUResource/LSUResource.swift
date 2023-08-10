import FeaturePrelude

extension PoolUnitsList {
	// MARK: - LSUResource
	public struct LSUResource: Sendable, FeatureReducer {
		public struct State: Sendable, Hashable {
			var isExpanded: Bool = false

			let stakes: [AccountPortfolio.PoolUnitResources.RadixNetworkStake]
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
