import ComposableArchitecture

// MARK: - AccountCompletion
public struct AccountCompletion: Sendable, ReducerProtocol {
	public init() {}
}

public extension AccountCompletion {
	func reduce(into state: inout State, action: Action) -> ComposableArchitecture.Effect<Action, Never> {
		switch action {
		case .internal(.view(.goToDestination)):
			return .run { send in
				await send(.delegate(.completed))
			}

		case .delegate:
			return .none
		}
	}
}
