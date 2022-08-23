import ComposableArchitecture

public extension Home.AccountDetails {
	// MARK: Reducer
	typealias Reducer = ComposableArchitecture.Reducer<State, Action, Environment>
	static let reducer = Reducer { _, action, _ in
		switch action {
		case .internal(.user(.dismissAccountDetails)):
			return .run { send in
				await send(.coordinate(.dismissAccountDetails))
			}
		case .coordinate:
			return .none
		}
	}
}
