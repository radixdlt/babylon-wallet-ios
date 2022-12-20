import ComposableArchitecture

public extension NonFungibleTokenList {
	struct Row: ReducerProtocol {
		public init() {}

		public func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
			switch action {
			case let .internal(.view(.selected(token))):
				return .run { send in await send(.delegate(.selected(token))) }

			case .internal(.view(.isExpandedToggled)):
				state.isExpanded.toggle()
				return .none

			case .delegate:
				return .none
			}
		}
	}
}
