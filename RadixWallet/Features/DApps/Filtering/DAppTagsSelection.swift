// MARK: - DAppTagsSelection
@Reducer
struct DAppTagsSelection: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		var selectedTags: OrderedSet<OnLedgerTag>
		let allTags: OrderedSet<OnLedgerTag>
	}

	typealias Action = FeatureAction<Self>

	enum ViewAction: Sendable, Equatable {
		case tagSelected(OnLedgerTag)
		case closeTapped
		case clearAllTapped
		case confirmTapped(OrderedSet<OnLedgerTag>)
	}

	enum DelegateAction: Sendable, Equatable {
		case selectedTags(OrderedSet<OnLedgerTag>)
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
			return .none
		case let .tagSelected(tag):
			state.selectedTags.toggle(tag)
			return .none
		case let .confirmTapped(tags):
			return .run { send in
				await send(.delegate(.selectedTags(tags)))
				await dismiss()
			}
		}
	}
}

extension DAppTagsSelection.State {
	var filterItems: IdentifiedArrayOf<ItemFilter<OnLedgerTag>> {
		allTags.map { tag in
			tag.asItemFilter(isActive: selectedTags.contains(tag))
		}.asIdentified()
	}
}

extension OnLedgerTag {
	func asItemFilter(isActive: Bool) -> ItemFilter<Self> {
		ItemFilter(id: self, icon: nil, label: self.name, isActive: isActive)
	}
}
