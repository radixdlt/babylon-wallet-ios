// MARK: - ChooseFactorSourceKind
@Reducer
struct ChooseFactorSourceKind: FeatureReducer {
	@ObservableState
	struct State: Hashable {
		let context: ChooseFactorSourceContext
		@SharedReader(.shieldBuilder) var shieldBuilder
	}

	typealias Action = FeatureAction<Self>

	enum ViewAction: Equatable {
		case kindTapped(FactorSourceKind)
		case disabledKindTapped
	}

	enum DelegateAction: Equatable {
		case chosenKind(FactorSourceKind)
	}

	@Dependency(\.overlayWindowClient) var overlayWindowClient

	var body: some ReducerOf<Self> {
		Reduce(core)
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case let .kindTapped(kind):
			return .send(.delegate(.chosenKind(kind)))
		case .disabledKindTapped:
			overlayWindowClient.showInfoLink(.init(glossaryItem: .buildingshield))
			return .none
		}
	}
}
