import ComposableArchitecture

public extension Home.Transfer {
	// MARK: Reducer
	typealias Reducer = ComposableArchitecture.Reducer<State, Action, Environment>
	static let reducer = Reducer { _, action, _ in
		switch action {
		case .internal(.user(.dismissTransfer)):
			return Effect(value: .coordinate(.dismissTransfer))
		case .coordinate:
			return .none
		}
	}
}
