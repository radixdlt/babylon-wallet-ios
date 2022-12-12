import ComposableArchitecture

// MARK: - FungibleTokenDetails
public struct FungibleTokenDetails: ReducerProtocol {
	public init() {}
}

public extension FungibleTokenDetails {
	func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.view(.closeButtonTapped)):
			return .run { send in await send(.delegate(.closeButtonTapped)) }
		case .delegate:
			return .none
		}
	}
}
