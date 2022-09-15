import ComposableArchitecture

public extension AccountDetails.AssetSection {
	// MARK: Reducer
	typealias Reducer = ComposableArchitecture.Reducer<State, Action, Environment>
	static let reducer = Reducer.combine(
		AccountDetails.AssetRow.reducer.forEach(
			state: \.assets,
			action: /AccountDetails.AssetSection.Action.asset(id:action:),
			environment: { _ in AccountDetails.AssetRow.Environment() }
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
