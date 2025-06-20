// MARK: - Discover.LearnAbout
extension Discover {
	// MARK: - LearnAbout
	@Reducer
	struct LearnAbout: Sendable, FeatureReducer {
		@ObservableState
		struct State: Sendable, Hashable {
			var learnItemsList: LearnItemsList.State = .withAllItems()

			var searchBarFocused: Bool = false
			var searchTerm: String = ""
		}

		typealias Action = FeatureAction<Self>

		@CasePathable
		enum ViewAction: Sendable, Equatable {
			case searchTermChanged(String)
			case focusChanged(Bool)
		}

		@CasePathable
		enum ChildAction: Sendable, Equatable {
			case learnItemsList(LearnItemsList.Action)
		}

		@Dependency(\.overlayWindowClient) var overlayWindowClient

		var body: some ReducerOf<Self> {
			Scope(state: \.learnItemsList, action: \.child.learnItemsList) {
				LearnItemsList()
			}

			Reduce(core)
		}

		func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
			switch viewAction {
			case let .searchTermChanged(term):
				state.searchTerm = term
				return updateDisplayedItems(state: &state)

			case let .focusChanged(isFocused):
				state.searchBarFocused = isFocused
				return .none
			}
		}

		func updateDisplayedItems(state: inout State) -> Effect<Action> {
			let searchTerm = state.searchTerm
			guard !searchTerm.isEmpty else {
				state.learnItemsList.displayedItems = state.learnItemsList.learnItems
				return .none
			}

			let searchTermWords = state.searchTerm.split(separator: " ")
			let allLearnItems = state.learnItemsList.learnItems

			let titleMatches = allLearnItems.filter {
				$0.title.localizedCaseInsensitiveContains(searchTerm)
			}

			let descriptionMatches = allLearnItems.filter {
				$0.description.localizedCaseInsensitiveContains(searchTerm)
			}

			let contentSearchTermMatches = allLearnItems.filter {
				$0.id.string.localizedStandardContains(searchTerm)
			}

			let contentWordMatches = allLearnItems.filter { item in
				searchTermWords.allSatisfy { word in
					item.id.string.localizedCaseInsensitiveContains(word)
				}
			}

			state.learnItemsList.displayedItems = titleMatches + descriptionMatches + contentSearchTermMatches + contentWordMatches
			return .none
		}
	}
}
