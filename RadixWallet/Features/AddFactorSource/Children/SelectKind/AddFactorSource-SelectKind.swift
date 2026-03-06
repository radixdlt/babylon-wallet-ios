extension AddFactorSource {
	@Reducer
	struct SelectKind: FeatureReducer {
		@ObservableState
		struct State: Hashable {
			let kinds: [FactorSourceKind]
			var selectedKind: FactorSourceKind?

			init(kinds: [FactorSourceKind]) {
				self.kinds = kinds
				self.selectedKind = nil
			}
		}

		typealias Action = FeatureAction<Self>

		@CasePathable
		enum ViewAction: Equatable {
			case didSelectKind(FactorSourceKind?)
			case continueButtonTapped(FactorSourceKind)
		}

		enum DelegateAction: Equatable {
			case completed(FactorSourceKind)
		}

		var body: some ReducerOf<Self> {
			Reduce(core)
		}

		func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
			switch viewAction {
			case let .didSelectKind(kind):
				state.selectedKind = kind
				return .none
			case let .continueButtonTapped(kind):
				return .send(.delegate(.completed(kind)))
			}
		}
	}
}
