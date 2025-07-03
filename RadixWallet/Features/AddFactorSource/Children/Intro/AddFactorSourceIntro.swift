// MARK: - AddFactorSourceIntro
extension AddFactorSource {
	@Reducer
	struct Intro: Sendable, FeatureReducer {
		@ObservableState
		struct State: Sendable, Hashable {
			let kind: FactorSourceKind
		}

		typealias Action = FeatureAction<Self>

		enum ViewAction: Sendable, Equatable {
			case continueTapped
		}

		enum DelegateAction: Sendable, Equatable {
			case completed
		}

		var body: some ReducerOf<Self> {
			Reduce(core)
		}

		func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
			switch viewAction {
			case .continueTapped:
				.send(.delegate(.completed))
			}
		}
	}
}
