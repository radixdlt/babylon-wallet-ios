// MARK: - StakeUnitList

public struct StakeUnitList: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var lsuResource: LSUResource.State?
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
	}

	public init() {}

	public func reduce(into _: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			.none
		}
	}
}
