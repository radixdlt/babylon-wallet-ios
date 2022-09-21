import ComposableArchitecture

public extension CreateAccount {
	// MARK: Reducer
	typealias Reducer = ComposableArchitecture.Reducer<State, Action, Environment>
	static let reducer = Reducer { _, action, _ in
		switch action {
		case .coordinate(.dismissCreateAccount):
			return .none
		}
	}
}
