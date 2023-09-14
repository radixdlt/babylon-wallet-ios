import FeaturePrelude

// MARK: - PoolUnitsList
public struct PoolUnitsList: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		var lsuResource: LSUResource.State?

		var poolUnits: IdentifiedArrayOf<PoolUnit.State> = []
	}

	public enum ChildAction: Sendable, Equatable {
		case lsuResource(LSUResource.Action)
		case poolUnit(id: PoolUnit.State.ID, action: PoolUnit.Action)
	}

	public init() {}

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(
				\.lsuResource,
				action: /Action.child .. ChildAction.lsuResource,
				then: LSUResource.init
			)
			.forEach(
				\.poolUnits,
				action: /Action.child .. ChildAction.poolUnit,
				element: PoolUnit.init
			)
	}
}
