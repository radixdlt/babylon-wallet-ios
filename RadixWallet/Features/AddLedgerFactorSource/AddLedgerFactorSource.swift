
typealias LedgerDeviceInfo = P2P.ConnectorExtension.Response.LedgerHardwareWallet.Success.GetDeviceInfo

// MARK: - AddLedgerFactorSource
@Reducer
struct AddLedgerFactorSource: Sendable, FeatureReducer {
	// MARK: AddLedgerFactorSource

	@ObservableState
	struct State: Sendable, Hashable {
		var isWaitingForResponseFromLedger = false
		var unnamedDeviceToAdd: LedgerDeviceInfo?

		@Presents
		var destination: Destination.State? = nil

		init() {}
	}

	typealias Action = FeatureAction<Self>

	enum ViewAction: Sendable, Equatable {
		case sendAddLedgerRequestButtonTapped
		case closeButtonTapped
	}

	enum InternalAction: Sendable, Equatable {
		case getDeviceInfoResult(TaskResult<LedgerDeviceInfo>)
		case alreadyExists(LedgerHardwareWalletFactorSource)
		case proceedToNameDevice(LedgerDeviceInfo)
	}

	enum DelegateAction: Sendable, Equatable {
		case completed(LedgerHardwareWalletFactorSource)
		case failedToAddLedger
		case dismiss
	}

	// MARK: Destination

	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Sendable, Hashable {
			case ledgerAlreadyExistsAlert(AlertState<Never>)
			case nameLedger(NameLedgerFactorSource.State)
		}

		@CasePathable
		enum Action: Sendable, Equatable {
			case ledgerAlreadyExistsAlert(Never)
			case nameLedger(NameLedgerFactorSource.Action)
		}

		var body: some ReducerOf<Self> {
			Scope(state: \.nameLedger, action: \.nameLedger) {
				NameLedgerFactorSource()
			}
		}
	}

	// MARK: Reduce

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.factorSourcesClient) var factorSourcesClient
	@Dependency(\.ledgerHardwareWalletClient) var ledgerHardwareWalletClient
	@Dependency(\.radixConnectClient) var radixConnectClient

	init() {}

	var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .sendAddLedgerRequestButtonTapped:
			sendAddLedgerRequestEffect(&state)

		case .closeButtonTapped:
			.send(.delegate(.dismiss))
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .getDeviceInfoResult(.success(ledgerDeviceInfo)):
			return gotDeviceEffect(ledgerDeviceInfo, in: &state)

		case let .getDeviceInfoResult(.failure(error)):
			return failedToGetDevice(&state, error: error)

		case let .alreadyExists(ledger):
			state.destination = .ledgerAlreadyExistsAlert(.ledgerAlreadyExists(ledger))
			return .none

		case let .proceedToNameDevice(device):
			state.destination = .nameLedger(.init(deviceInfo: device))
			return .none
		}
	}

	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case let .nameLedger(.delegate(.complete(ledger))):
			completeWithLedgerEffect(ledger)

		case .nameLedger(.delegate(.failedToCreateLedgerFactorSource)):
			.send(.delegate(.failedToAddLedger))

		default:
			.none
		}
	}

	// MARK: Helper methods

	private func sendAddLedgerRequestEffect(_ state: inout State) -> Effect<Action> {
		state.isWaitingForResponseFromLedger = true
		return .run { send in
			let result = await TaskResult {
				try await ledgerHardwareWalletClient.getDeviceInfo()
			}

			await send(.internal(.getDeviceInfoResult(result)))
		}
	}

	private func gotDeviceEffect(_ ledgerDeviceInfo: LedgerDeviceInfo, in state: inout State) -> Effect<Action> {
		state.isWaitingForResponseFromLedger = false
		loggerGlobal.notice("Successfully received response from CE! \(ledgerDeviceInfo) ✅")
		return .run { send in

			if let ledger = try await factorSourcesClient.getFactorSource(
				id: FactorSourceID.hash(value: FactorSourceIdFromHash(kind: .ledgerHqHardwareWallet, body: Exactly32Bytes(bytes: ledgerDeviceInfo.id.data.data))),
				as: LedgerHardwareWalletFactorSource.self
			) {
				await send(.internal(.alreadyExists(ledger)))
			} else {
				await send(.internal(.proceedToNameDevice(ledgerDeviceInfo)))
			}

		} catch: { error, _ in
			errorQueue.schedule(error)
		}
	}

	private func failedToGetDevice(_ state: inout State, error: Swift.Error) -> Effect<Action> {
		state.isWaitingForResponseFromLedger = false
		loggerGlobal.error("Failed to get ledger device info: \(error)")
		errorQueue.schedule(error)
		return .none
	}

	private func completeWithLedgerEffect(_ ledger: LedgerHardwareWalletFactorSource) -> Effect<Action> {
		.run { send in
			try await factorSourcesClient.saveFactorSource(ledger.asGeneral)
			loggerGlobal.notice("Added Ledger factor source! ✅ ")
			await send(.delegate(.completed(ledger)))
		} catch: { error, _ in
			loggerGlobal.error("Failed to add Factor Source, error: \(error)")
			errorQueue.schedule(error)
		}
	}
}

extension AlertState<Never> {
	static func ledgerAlreadyExists(_ ledger: LedgerHardwareWalletFactorSource) -> AlertState {
		AlertState {
			TextState(L10n.AddLedgerDevice.AlreadyAddedAlert.title)
		} message: {
			TextState(L10n.AddLedgerDevice.AlreadyAddedAlert.message(ledger.hint.label))
		}
	}
}
