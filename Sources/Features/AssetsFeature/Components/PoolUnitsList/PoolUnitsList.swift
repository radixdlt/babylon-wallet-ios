import FeaturePrelude

// MARK: - PoolUnitsList
public struct PoolUnitsList: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		let isExpanded: Bool

		public init(isExpanded: Bool) {
			self.isExpanded = isExpanded
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared

		case isExpandedToggled
	}

	public init() {}

	public func reduce(
		into state: inout State,
		viewAction: ViewAction
	) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .none

		case .isExpandedToggled:
			return .none
		}
	}
}
