import ComposableArchitecture

// MARK: - ImportOlympiaNameLedger
struct ImportOlympiaNameLedger: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		var nameLedger: NameLedgerFactorSource.State

		init(deviceInfo: LedgerDeviceInfo) {
			self.nameLedger = .init(deviceInfo: deviceInfo)
		}
	}

	enum ViewAction: Sendable, Equatable {
		case closeButtonTapped
	}

	@CasePathable
	enum ChildAction: Sendable, Equatable {
		case nameLedger(NameLedgerFactorSource.Action)
	}

	enum DelegateAction: Sendable, Equatable {
		case savedNewLedger(LedgerHardwareWalletFactorSource)
		case failedToSaveNewLedger
	}

	@Dependency(\.dismiss) var dismiss
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.factorSourcesClient) var factorSourcesClient

	init() {}

	var body: some ReducerOf<Self> {
		Scope(state: \.nameLedger, action: /Action.child .. ChildAction.nameLedger) {
			NameLedgerFactorSource()
		}
		Reduce(core)
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .closeButtonTapped:
			.run { _ in
				await dismiss()
			}
		}
	}

	func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .nameLedger(.delegate(.complete(ledger))):
			saveNewLedger(ledger)

		case .nameLedger(.delegate(.failedToCreateLedgerFactorSource)):
			.send(.delegate(.failedToSaveNewLedger))

		default:
			.none
		}
	}

	private func saveNewLedger(_ ledger: LedgerHardwareWalletFactorSource) -> Effect<Action> {
		.run { send in
			try await factorSourcesClient.saveFactorSource(ledger.asGeneral)
			loggerGlobal.notice("Saved Ledger factor source! ✅")
			await send(.delegate(.savedNewLedger(ledger)))
		} catch: { error, _ in
			loggerGlobal.error("Failed to save Factor Source, error: \(error)")
			errorQueue.schedule(error)
		}
	}
}
