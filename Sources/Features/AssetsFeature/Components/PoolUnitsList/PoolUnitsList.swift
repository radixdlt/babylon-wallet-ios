import FeaturePrelude

// MARK: - PoolUnitsList
public struct PoolUnitsList: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		var lsuResource: LSUResource.State?

		var lpTokens: IdentifiedArrayOf<LPToken.State> = []
	}

	public enum ChildAction: Sendable, Equatable {
		case lsuResource(LSUResource.Action)
		case lpTokens(id: LPToken.State.ID, action: LPToken.Action)
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
				element: LPToken.init
			)
	}
}

extension PoolUnitsList.State {
	public static var preview: Self {
		.init(
			lsuResource: .init(),
			lpTokens: [
				.init(id: 0),
				.init(id: 2),
			]
		)
	}
}
