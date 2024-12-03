extension PrepareFactors {
	@Reducer
	struct AddHardwareFactor: Sendable, FeatureReducer {
		@ObservableState
		struct State: Sendable, Hashable {
			var selected: FactorSourceKind?
		}

		typealias Action = FeatureAction<Self>

		enum ViewAction: Sendable, Equatable {
			case selected(FactorSourceKind)
			case addButtonTapped
			case noDeviceButtonTapped
		}

		enum DelegateAction: Sendable, Equatable {
			case addedFactorSource
		}

		var body: some ReducerOf<Self> {
			Reduce(core)
		}

		func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
			switch viewAction {
			case let .selected(value):
				state.selected = value
				return .none
			case .addButtonTapped:
				// Present flow to add Ledger or Arculus
				return .send(.delegate(.addedFactorSource))
			case .noDeviceButtonTapped:
				// Present alert
				return .none
			}
		}
	}
}
