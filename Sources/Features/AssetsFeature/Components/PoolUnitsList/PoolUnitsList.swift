import FeaturePrelude

// MARK: - PoolUnitsList
public struct PoolUnitsList: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		var lsuResource: LSUResource.State?

		var lpTokens: IdentifiedArrayOf<PoolUnit.State> = []
	}

	public enum ChildAction: Sendable, Equatable {
		case lsuResource(LSUResource.Action)
		case lpTokens(id: PoolUnit.State.ID, action: PoolUnit.Action)
	}

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(
				\.lsuResource,
				action: /Action.child .. ChildAction.lsuResource,
				then: LSUResource.init
			)
			.forEach(
				\.lpTokens,
				action: /Action.child .. ChildAction.lpTokens,
				element: PoolUnit.init
			)
	}
}

extension PoolUnitsList.State {
	public static var preview: Self {
		.init(
			lsuResource: nil,
			lpTokens: []
		)
	}
}
