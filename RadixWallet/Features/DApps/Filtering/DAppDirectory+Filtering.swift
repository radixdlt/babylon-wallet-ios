// MARK: - DAppsFiltering
@Reducer
struct DAppsFiltering: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		var searchBarFocused: Bool = false
		var searchTerm: String = ""
		var filterTags: OrderedSet<OnLedgerTag> = []
		var allTags: OrderedSet<OnLedgerTag> = []

		@Presents
		var destination: Destination.State? = nil
	}

	typealias Action = FeatureAction<Self>

	@CasePathable
	enum ViewAction: Sendable, Equatable {
		case searchTermChanged(String)
		case focusChanged(Bool)
		case filtersTapped
		case filterRemoved(OnLedgerTag)
	}

	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Hashable, Sendable {
			case tagSelection(DAppTagsSelection.State)
		}

		@CasePathable
		enum Action: Equatable, Sendable {
			case tagSelection(DAppTagsSelection.Action)
		}

		var body: some ReducerOf<Self> {
			Scope(state: \.tagSelection, action: \.tagSelection) {
				DAppTagsSelection()
			}
		}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(destinationPath, action: \.destination) {
				Destination()
			}
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case let .searchTermChanged(searchTerm):
			state.searchTerm = searchTerm.trimmingWhitespacesAndNewlines()
			return .none

		case let .focusChanged(isFocused):
			state.searchBarFocused = isFocused
			return .none

		case .filtersTapped:
			state.destination = .tagSelection(.init(selectedTags: state.filterTags, allTags: state.allTags))
			return .none

		case let .filterRemoved(tag):
			state.filterTags.remove(tag)
			return .none
		}
	}

	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case let .tagSelection(.delegate(.selectedTags(tags))):
			state.filterTags = tags
			return .none
		default:
			return .none
		}
	}
}
