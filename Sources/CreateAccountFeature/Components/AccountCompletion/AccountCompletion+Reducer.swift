import ComposableArchitecture

// MARK: - CreateAccount
public struct AccountCompletion: ReducerProtocol {
	public init() {}

	public func reduce(into _: inout State, action _: Action) -> ComposableArchitecture.Effect<Action, Never> {
		.none
	}
}
