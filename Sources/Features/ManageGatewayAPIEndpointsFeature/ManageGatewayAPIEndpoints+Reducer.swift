import ComposableArchitecture

// MARK: - ManageGatewayAPIEndpoints
public struct ManageGatewayAPIEndpoints: ReducerProtocol {
	public init() {}
}

public extension ManageGatewayAPIEndpoints {
	func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.view(.dismissButtonTapped)):
			return .run { send in
				await send(.delegate(.dismiss))
			}
		case let .internal(.view(.gatewayAPIURLChanged(url))):
			state.gatewayAPIURLString = url
			return .none
		case .delegate:
			return .none
		}
	}
}
