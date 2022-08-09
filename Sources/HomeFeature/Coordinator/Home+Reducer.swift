import ComposableArchitecture

public extension Home {
	// MARK: Reducer
	typealias Reducer = ComposableArchitecture.Reducer<State, Action, Environment>
	static let reducer = Reducer.combine(
		Home.Header.reducer
			.pullback(
				state: \.header,
				action: /Home.Action.header,
				environment: { _ in Home.Header.Environment() }
			),

		Home.Balance.reducer
			.pullback(
				state: \.balance,
				action: /Home.Action.balance,
				environment: { _ in Home.Balance.Environment() }
			),

		Home.VisitHub.reducer
			.pullback(
				state: \.visitHub,
				action: /Home.Action.visitHub,
				environment: { _ in Home.VisitHub.Environment() }
			),

		Reducer { _, action, _ in
			switch action {
			case .header(.coordinate(.displaySettings)):
				return Effect(value: .coordinate(.displaySettings))
			case .header(.internal(_)):
				return .none
			case .balance:
				return .none
			case .visitHub(.coordinate(.displayHub)):
				return Effect(value: .coordinate(.displayVisitHub))
			case .visitHub(.internal(_)):
				return .none
			case .coordinate:
				return .none
			}
		}
	)
}
