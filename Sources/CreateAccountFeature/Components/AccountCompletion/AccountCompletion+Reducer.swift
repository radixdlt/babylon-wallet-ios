import ComposableArchitecture

// MARK: - AccountCompletion
public struct AccountCompletion: ReducerProtocol {
	public init() {}
}

public extension AccountCompletion {
	func reduce(into _: inout State, action _: Action) -> ComposableArchitecture.Effect<Action, Never> {
		.none
	}
}
