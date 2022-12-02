import ComposableArchitecture

// MARK: - NewConnection
public struct NewConnection: Sendable, ReducerProtocol {
	public init() {}
}

public extension NewConnection {
	func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
		.none
	}
}
