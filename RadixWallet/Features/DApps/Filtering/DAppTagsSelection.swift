// MARK: - DAppTagsSelection
@Reducer
struct DAppTagsSelection: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		var selectedTags: OrderedSet<DAppsDirectoryClient.DApp.Tag>
	}

	typealias Action = FeatureAction<Self>

	enum ViewAction: Sendable, Equatable {
		case tagSelected(DAppsDirectoryClient.DApp.Tag)
		case closeTapped
		case clearAllTapped
	}

	enum DelegateAction: Sendable, Equatable {
		case selectedTags(OrderedSet<DAppsDirectoryClient.DApp.Tag>)
	}

	@Dependency(\.dismiss) var dismiss

	var body: some ReducerOf<Self> {
		Reduce(core)
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .closeTapped:
			return .run { _ in await dismiss() }
		case .clearAllTapped:
			state.selectedTags.removeAll()
			return .send(.delegate(.selectedTags(state.selectedTags)))
		case let .tagSelected(tag):
			state.selectedTags.toggle(tag)
			return .send(.delegate(.selectedTags(state.selectedTags)))
		}
	}
}

extension DAppTagsSelection.State {
	var filterItems: IdentifiedArrayOf<ItemFilter<DAppsDirectoryClient.DApp.Tag>> {
		DAppsDirectoryClient.DApp.Tag.allCases.map { tag in
			tag.asItemFilter(isActive: selectedTags.contains(tag))
		}.asIdentified()
	}
}

extension DAppsDirectoryClient.DApp.Tag {
	func asItemFilter(isActive: Bool) -> ItemFilter<Self> {
		ItemFilter(id: self, icon: nil, label: self.title, isActive: isActive)
	}
}
