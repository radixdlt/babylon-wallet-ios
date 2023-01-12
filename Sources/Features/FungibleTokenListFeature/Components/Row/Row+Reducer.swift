import FeaturePrelude

public extension FungibleTokenList {
	struct Row: Sendable, ReducerProtocol {
		public init() {}

		public func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
			switch action {
			case .internal(.view(.selected)):
				return .run { [token = state.container] send in
					await send(.delegate(.selected(token)))
				}
			case .internal:
				return .none
			case .delegate:
				return .none
			}
		}
	}
}
