extension Discover {
	// MARK: - LearnAbout
	@Reducer
	struct LearnAbout: Sendable, FeatureReducer {
		@ObservableState
		struct State: Sendable, Hashable {
			let learnItems: IdentifiedArrayOf<LearnItem>
			var searchBarFocused: Bool = false
			var searchTerm: String = ""
		}

		typealias Action = FeatureAction<Self>

		@CasePathable
		enum ViewAction: Sendable, Equatable {
			case searchTermChanged(String)
			case learnItemTapped(LearnItem)
			case focusChanged(Bool)
		}

		var body: some ReducerOf<Self> {
			Reduce(core)
		}

		func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
			switch viewAction {
			case let .searchTermChanged(term):
				state.searchTerm = term
				return .none
			case let .learnItemTapped(item):
				return .none
			case let .focusChanged(isFocused):
				state.searchBarFocused = isFocused
				return .none
			}
		}
	}
}
