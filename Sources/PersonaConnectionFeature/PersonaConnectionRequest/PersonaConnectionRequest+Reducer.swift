import ComposableArchitecture

// MARK: - PersonaConnectionRequest
public struct PersonaConnectionRequest: ReducerProtocol {
	public init() {}
}

public extension PersonaConnectionRequest {
	func reduce(into _: inout State, action _: Action) -> ComposableArchitecture.Effect<Action, Never> {
		.none
	}
}
