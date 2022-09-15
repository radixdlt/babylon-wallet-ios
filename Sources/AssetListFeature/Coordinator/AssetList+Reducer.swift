import ComposableArchitecture

public extension AssetList {
	// MARK: Reducer
	typealias Reducer = ComposableArchitecture.Reducer<State, Action, Environment>
	static let reducer = Reducer.combine(
		AssetList.Section.reducer.forEach(
			state: \.sections,
			action: /AssetList.Action.section,
			environment: { _ in AssetList.Section.Environment() }
		),

		Reducer { _, action, _ in
			switch action {
			case .internal:
				return .none
			case .coordinate:
				return .none
			case .section:
				return .none
			}
		}
	)
}
