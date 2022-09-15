import ComposableArchitecture

public extension AssetList.Section {
	// MARK: Reducer
	typealias Reducer = ComposableArchitecture.Reducer<State, Action, Environment>
	static let reducer = Reducer.combine(
		AssetList.Row.reducer.forEach(
			state: \.assets,
			action: /AssetList.Section.Action.asset(id:action:),
			environment: { _ in AssetList.Row.Environment() }
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
