import ComposableArchitecture

// MARK: - SelectFactorSources
@Reducer
struct RegularAccessSetup: FeatureReducer, Sendable {
	@ObservableState
	struct State: Hashable, Sendable {
		@Shared(.shieldBuilder) var shieldBuilder
	}

	typealias Action = FeatureAction<Self>

	@CasePathable
	enum ViewAction: Equatable, Sendable {
		case task
		case continueButtonTapped
	}

	enum DelegateAction: Equatable, Sendable {
		case finished
	}

	var body: some ReducerOf<Self> {
		Reduce(core)
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task, .continueButtonTapped:
			.none
		}
	}
}
