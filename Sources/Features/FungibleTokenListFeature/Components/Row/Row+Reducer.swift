import ComposableArchitecture

public extension FungibleTokenList {
	struct Row: ReducerProtocol {
		public init() {}

		public func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
			switch action {
			case .internal:
				return .none
			case .delegate:
				return .none
			}
		}
	}
}
