// MARK: - NameLedgerFactorSource
@Reducer
struct NameLedgerFactorSource: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		let deviceInfo: LedgerDeviceInfo
		var ledgerName = ""

		var nameIsValid: Bool {
			!ledgerName.isEmpty
		}
	}

	typealias Action = FeatureAction<Self>

	@CasePathable
	enum ViewAction: Sendable, Equatable {
		case ledgerNameChanged(String)
		case confirmNameButtonTapped
	}

	enum DelegateAction: Sendable, Equatable {
		case complete(LedgerHardwareWalletFactorSource)
		case failedToCreateLedgerFactorSource
	}

	@Dependency(\.errorQueue) var errorQueue

	var body: some ReducerOf<Self> {
		Reduce(core)
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case let .ledgerNameChanged(name):
			state.ledgerName = name
			return .none

		case .confirmNameButtonTapped:
			loggerGlobal.notice("Confirmed ledger name: '\(state.ledgerName)', creating factor source")

			do {
				let ledger = try LedgerHardwareWalletFactorSource.from(
					device: state.deviceInfo,
					name: state.ledgerName
				)
				return .send(.delegate(.complete(ledger)))
			} catch {
				loggerGlobal.error("Failed to created Ledger FactorSource, error: \(error)")
				errorQueue.schedule(error)
				return .send(.delegate(.failedToCreateLedgerFactorSource))
			}
		}
	}
}
