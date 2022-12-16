import ComposableArchitecture

// MARK: - AccountCompletion
public struct AccountCompletion: ReducerProtocol {
	public init() {}
}

public extension AccountCompletion {
	func reduce(into state: inout State, action: Action) -> ComposableArchitecture.Effect<Action, Never> {
		switch action {
		case .internal(.view(.goToDestination)):
			switch state.destination {
			case .home:
				return .run { send in
					await send(.delegate(.displayHome))
				}
			case .chooseAccounts:
				return .run { send in
					await send(.delegate(.displayChooseAccounts))
				}
			}

		case .delegate:
			return .none
		}
	}
}
