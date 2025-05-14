// MARK: - ThemeSelection
@Reducer
struct ThemeSelection: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		var appTheme: AppTheme = .system

		init() {}
	}

	typealias Action = FeatureAction<Self>

	@CasePathable
	enum ViewAction: Sendable, Equatable {
		case appeared
		case themeChanged(AppTheme)
	}

	@Dependency(\.userDefaults) var userDefaults
	var body: some ReducerOf<Self> {
		Reduce(core)
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			state.appTheme = userDefaults.getPreferredTheme()
			return .none
		case let .themeChanged(theme):
			state.appTheme = theme
			userDefaults.setPreferredTheme(theme)
			return .none
		}
	}
}
