// MARK: - PrepareFactorSources.AddFactorSource
extension PrepareFactorSources {
	@Reducer
	struct AddFactorSource: Sendable, FeatureReducer {
		@ObservableState
		struct State: Sendable, Hashable {
			let mode: Mode
			var selected: FactorSourceKind?
		}

		typealias Action = FeatureAction<Self>

		enum ViewAction: Sendable, Equatable {
			case selected(FactorSourceKind)
			case addButtonTapped
		}

		enum DelegateAction: Sendable, Equatable {
			case addFactorSource(FactorSourceKind)
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
				guard let selected = state.selected else {
					return .none
				}
				return .send(.delegate(.addFactorSource(selected)))
			}
		}
	}
}

// MARK: - PrepareFactorSources.AddFactorSource.State.Mode
extension PrepareFactorSources.AddFactorSource.State {
	enum Mode {
		case hardware
		case any
	}
}
