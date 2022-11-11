import ComposableArchitecture

public extension NonFungibleTokenList {
	struct Row: ReducerProtocol {
		public init() {}

		public func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
			switch action {
			case .internal(.view(.isExpandedToggled)):
				state.isExpanded.toggle()
				return .none

			case .delegate:
				return .none
			}
		}
	}
}
