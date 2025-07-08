import ComposableArchitecture
import SwiftUI

// MARK: - SelectedLedgerControlRequirements
struct SelectedLedgerControlRequirements: Hashable {
	let selectedLedger: LedgerHardwareWalletFactorSource
}

// MARK: - LedgerHardwareDevices
struct LedgerHardwareDevices: Sendable, FeatureReducer {
	// MARK: - State

	struct State: Sendable, Hashable {
		enum Context: Sendable, Hashable {
			case settings
			case createHardwareAccount
			case accountRecovery(olympia: Bool)
			case setupMFA
		}

		let context: Context

		var hasAConnectorExtension: Bool = false

		@Loadable
		var ledgers: IdentifiedArrayOf<LedgerHardwareWalletFactorSource>? = nil

		var selectedLedgerID: FactorSourceIDFromHash? = nil
		let selectedLedgerControlRequirements: SelectedLedgerControlRequirements? = nil

		@PresentationState
		var destination: Destination.State? = nil

		var pendingAction: ActionRequiringP2P? = nil

		init(context: Context) {
			self.context = context
		}
	}

	enum ActionRequiringP2P: Sendable, Hashable {
		case addLedger
		case selectLedger(LedgerHardwareWalletFactorSource)
	}

	// MARK: - Action

	enum ViewAction: Sendable, Equatable {
		case onFirstTask
		case selectedLedger(id: FactorSourceIDFromHash?)
		case addNewLedgerButtonTapped
		case confirmedLedger(LedgerHardwareWalletFactorSource)
		case whatIsALedgerButtonTapped
	}

	enum InternalAction: Sendable, Equatable {
		case loadedLedgers(TaskResult<IdentifiedArrayOf<LedgerHardwareWalletFactorSource>>)
		case hasAConnectorExtension(Bool)
		case perform(ActionRequiringP2P)
	}

	enum DelegateAction: Sendable, Equatable {
		case choseLedger(LedgerHardwareWalletFactorSource)
		// Only used when in the `accountRecovery` context
		case choseLedgerForRecovery(LedgerHardwareWalletFactorSource, isOlympia: Bool)
	}

	// MARK: - Destination

	struct Destination: DestinationReducer {
		enum State: Sendable, Hashable {
			case noP2PLink(AlertState<NoP2PLinkAlert>)
			case addNewP2PLink(NewConnection.State)
			case addNewLedger(AddLedgerFactorSource.State)
		}

		enum Action: Sendable, Equatable {
			case noP2PLink(NoP2PLinkAlert)
			case addNewP2PLink(NewConnection.Action)
			case addNewLedger(AddLedgerFactorSource.Action)
		}

		var body: some ReducerOf<Self> {
			Scope(state: /State.addNewP2PLink, action: /Action.addNewP2PLink) {
				NewConnection()
			}
			Scope(state: /State.addNewLedger, action: /Action.addNewLedger) {
				AddLedgerFactorSource()
			}
		}
	}

	// MARK: - Reducer

	@Dependency(\.factorSourcesClient) var factorSourcesClient
	@Dependency(\.ledgerHardwareWalletClient) var ledgerHardwareWalletClient
	@Dependency(\.radixConnectClient) var radixConnectClient
	@Dependency(\.errorQueue) var errorQueue

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
		case .onFirstTask:
			return .merge(updateLedgersEffect(state: &state), checkP2PLinkEffect())

		case let .selectedLedger(selectedID):
			state.selectedLedgerID = selectedID
			return .none

		case let .confirmedLedger(ledger):
			return performActionRequiringP2PEffect(.selectLedger(ledger), in: &state)

		case .addNewLedgerButtonTapped:
			return performActionRequiringP2PEffect(.addLedger, in: &state)

		case .whatIsALedgerButtonTapped:
			return .none
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .loadedLedgers(result):
			state.$ledgers = .init(result: result)
			return .none

		case let .hasAConnectorExtension(isConnected):
			loggerGlobal.notice("Is connected to any CE?: \(isConnected)")
			state.hasAConnectorExtension = isConnected

			if isConnected, let pendingAction = state.pendingAction {
				return performActionRequiringP2PEffect(pendingAction, in: &state)
			} else {
				return .none
			}

		case let .perform(action):
			return performActionRequiringP2PEffect(action, in: &state)
		}
	}

	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case let .noP2PLink(alertAction):
			switch alertAction {
			case .addNewP2PLinkTapped:
				state.destination = .addNewP2PLink(.init())
				return .none

			case .cancelTapped:
				return .none
			}

		case let .addNewP2PLink(.delegate(newP2PAction)):
			switch newP2PAction {
			case .newConnection:
				state.destination = nil
				return .none
			}

		case let .addNewLedger(.delegate(newLedgerAction)):
			switch newLedgerAction {
			case let .completed(ledger):
				state.destination = nil
				state.selectedLedgerID = ledger.id
				return updateLedgersEffect(state: &state)
			case .failedToAddLedger:
				state.destination = nil
				return .none
//			case .dismiss:
//				state.destination = nil
//				return .none
			}

		default:
			return .none
		}
	}

	private func updateLedgersEffect(state: inout State) -> Effect<Action> {
		state.$ledgers = .loading
		return .run { send in
			let result = await TaskResult {
				let ledgers = try await factorSourcesClient.getFactorSources(type: LedgerHardwareWalletFactorSource.self)
				return IdentifiedArray(uniqueElements: ledgers)
			}
			await send(.internal(.loadedLedgers(result)))
		}
	}

	private func checkP2PLinkEffect() -> Effect<Action> {
		.run { send in
			let hasAConnectorExtension = await ledgerHardwareWalletClient.hasAnyLinkedConnector()
			await send(.internal(.hasAConnectorExtension(hasAConnectorExtension)))
		} catch: { error, _ in
			loggerGlobal.error("failed to get links updates, error: \(error)")
		}
	}

	private func performActionRequiringP2PEffect(_ action: ActionRequiringP2P, in state: inout State) -> Effect<Action> {
		// If we don't have a connection, we remember what we were trying to do and then ask if they want to link one
		guard state.hasAConnectorExtension else {
			state.pendingAction = action
			state.destination = .noP2PLink(.noP2Plink)
			return .none
		}

		state.pendingAction = nil

		// If we have a connection, we can proceed directly
		switch action {
		case .addLedger:
			state.destination = .addNewLedger(.init())
			return .none
		case let .selectLedger(ledger):
			if case let .accountRecovery(olympia: olympia) = state.context {
				return .send(.delegate(.choseLedgerForRecovery(ledger, isOlympia: olympia)))
			} else {
				return .send(.delegate(.choseLedger(ledger)))
			}
		}
	}
}
