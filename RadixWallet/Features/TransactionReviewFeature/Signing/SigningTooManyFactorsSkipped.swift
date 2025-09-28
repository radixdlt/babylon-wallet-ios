// MARK: - SigningTooManyFactorsSkipped
@Reducer
struct SigningTooManyFactorsSkipped: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		enum Intent: Sendable, Hashable {
			case transaction(TransactionIntent)
			case preAuth(Subintent)
		}

		let intent: Intent
	}

	typealias Action = FeatureAction<Self>

	enum ViewAction: Sendable, Equatable {
		case restartButtonTapped
		case cancelButtonTapped
	}

	enum DelegateAction: Sendable, Equatable {
		case restart(State.Intent)
		case cancel
	}

	var body: some ReducerOf<Self> {
		Reduce(core)
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .restartButtonTapped:
			.send(.delegate(.restart(state.intent)))
		case .cancelButtonTapped:
			.send(.delegate(.cancel))
		}
	}
}
