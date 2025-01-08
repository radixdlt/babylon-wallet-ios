// MARK: - ChooseFactorSourceKind
@Reducer
struct ChooseFactorSourceKind: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		@Shared(.shieldBuilder) var shieldBuilder

		var aux: [FactorSourceKind: Bool] = [:]
	}

	typealias Action = FeatureAction<Self>

	enum ViewAction: Sendable, Equatable {
		case kindTapped(FactorSourceKind)
		case disabledKindTapped
	}

	enum DelegateAction: Sendable, Equatable {
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
