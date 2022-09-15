import ComposableArchitecture

public extension AccountDetails.AssetList {
	// MARK: Reducer
	typealias Reducer = ComposableArchitecture.Reducer<State, Action, Environment>
	static let reducer = Reducer.combine(
		AccountDetails.AssetSection.reducer.forEach(
			state: \.sections,
			action: /AccountDetails.AssetList.Action.assetSection,
			environment: { _ in AccountDetails.AssetSection.Environment() }
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
