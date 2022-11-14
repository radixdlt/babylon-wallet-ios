import ComposableArchitecture

// MARK: - ManageGatewayAPIEndpoints
public struct ManageGatewayAPIEndpoints: ReducerProtocol {
	public init() {}
}

public extension ManageGatewayAPIEndpoints {
	func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
		.none
	}
}
