import ComposableArchitecture

public extension Home.AssetSection {
	// MARK: Reducer
	typealias Reducer = ComposableArchitecture.Reducer<State, Action, Environment>
	static let reducer = Reducer.combine(
		Home.AssetRow.reducer.forEach(
			state: \.assets,
			action: /Home.AssetSection.Action.asset(id:action:),
			environment: { _ in Home.AssetRow.Environment() }
		),

		Reducer { _, action, _ in
			switch action {
			case .internal:
				return .none
			case .coordinate:
				return .none
			case let .asset(id: id, action: action):
				return .none
			}
		}
	)
}
