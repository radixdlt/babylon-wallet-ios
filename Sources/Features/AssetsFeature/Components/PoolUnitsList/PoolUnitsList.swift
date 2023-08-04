import FeaturePrelude

// MARK: - PoolUnitsList
public struct PoolUnitsList: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		var lsuResource: LSUResource.State?

		var poolUnitTokens: IdentifiedArrayOf<PoolUnitToken.State> = []
	}

	public enum ChildAction: Sendable, Equatable {
		case lsuResource(LSUResource.Action)
		case poolUnitTokens(id: PoolUnitToken.State.ID, action: PoolUnitToken.Action)
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
				\.poolUnitTokens,
				action: /Action.child .. ChildAction.poolUnitTokens,
				element: PoolUnitToken.init
			)
	}
}

extension PoolUnitsList.State {
	public static var preview: Self {
		.init(
			lsuResource: .init(),
			poolUnitTokens: [
				.init(id: 0),
				.init(id: 2),
			]
		)
	}
}
