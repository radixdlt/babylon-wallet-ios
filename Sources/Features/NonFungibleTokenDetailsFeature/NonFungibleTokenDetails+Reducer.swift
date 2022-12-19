import ComposableArchitecture

// MARK: - NonFungibleTokenDetails
public struct NonFungibleTokenDetails: ReducerProtocol {
	public init() {}
}

public extension NonFungibleTokenDetails {
	func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.view(.closeButtonTapped)):
			return .run { send in await send(.delegate(.closeButtonTapped)) }
		case .delegate:
			return .none
		}
	}
}
