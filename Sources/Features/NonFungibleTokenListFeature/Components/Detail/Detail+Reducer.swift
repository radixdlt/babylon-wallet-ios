import ComposableArchitecture

// MARK: - NonFungibleTokenList.Detail
public extension NonFungibleTokenList {
	// MARK: - NonFungibleTokenDetails
	struct Detail: ReducerProtocol {
		public init() {}
	}
}

public extension NonFungibleTokenList.Detail {
	func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.view(.closeButtonTapped)):
			return .run { send in await send(.delegate(.closeButtonTapped)) }
		case .delegate:
			return .none
		}
	}
}
