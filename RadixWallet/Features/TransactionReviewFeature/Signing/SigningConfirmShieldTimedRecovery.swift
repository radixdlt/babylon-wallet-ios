// MARK: - SigningConfirmShieldTimedRecovery
@Reducer
struct SigningConfirmShieldTimedRecovery: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		let periodUntilAutoConfirm: TimePeriod
		let notarizedTimedRecovery: NotarizeTransactionResponse
	}

	typealias Action = FeatureAction<Self>

	enum ViewAction: Sendable, Equatable {
		case fallbackInfoButtonTapped
		case useEmergencyFallbackButtonTapped
		case restartSigningButtonTapped
	}

	enum DelegateAction: Sendable, Equatable {
		case useEmergencyFallback(NotarizeTransactionResponse)
		case restartSigning(TransactionIntent)
	}

	@Dependency(\.overlayWindowClient) var overlayWindowClient

	var body: some ReducerOf<Self> {
		Reduce(core)
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .fallbackInfoButtonTapped:
			overlayWindowClient.showInfoLink(.init(glossaryItem: .emergencyfallback))
			return .none
		case .useEmergencyFallbackButtonTapped:
			return .send(.delegate(.useEmergencyFallback(state.notarizedTimedRecovery)))
		case .restartSigningButtonTapped:
			return .send(.delegate(.restartSigning(state.notarizedTimedRecovery.intent)))
		}
	}
}
