import ComposableArchitecture

public extension Home.CreateAccount {
	// MARK: Reducer
	typealias Reducer = ComposableArchitecture.Reducer<State, Action, Environment>
	static let reducer = Reducer { _, action, _ in
		switch action {
		case .coordinate(.dismissCreateAccount):
			return .none
		}
	}
}
