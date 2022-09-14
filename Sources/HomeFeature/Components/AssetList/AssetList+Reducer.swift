import ComposableArchitecture

public extension Home.AssetList {
	// MARK: Reducer
	typealias Reducer = ComposableArchitecture.Reducer<State, Action, Environment>
	static let reducer = Reducer.combine(
		Home.AssetSection.reducer.forEach(
			state: \.sections,
			action: /Home.AssetList.Action.assetSection,
			environment: { _ in Home.AssetSection.Environment() }
		),

		Reducer { _, action, _ in
			switch action {
			case .internal:
				return .none
			case .coordinate:
				return .none
			case .assetSection:
				return .none
			}
		}
	)
}
