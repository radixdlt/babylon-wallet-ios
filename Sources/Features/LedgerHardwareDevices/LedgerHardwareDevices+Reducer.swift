import AddLedgerFactorSourceFeature
import FactorSourcesClient
import FeaturePrelude
import NewConnectionFeature
import P2PLinksClient
import Profile

// MARK: - SelectedLedgerControlRequirements
struct SelectedLedgerControlRequirements: Hashable {
	let selectedLedger: LedgerFactorSource
}

// MARK: - LedgerHardwareDevices
public struct LedgerHardwareDevices: Sendable, FeatureReducer {
	// MARK: - State

	public struct State: Sendable, Hashable {
		public let allowSelection: Bool
		public let showHeaders: Bool

		public var hasAConnectorExtension: Bool = false

		@Loadable
		public var ledgers: IdentifiedArrayOf<LedgerFactorSource>? = nil

		public var selectedLedgerID: FactorSourceID? = nil
		let selectedLedgerControlRequirements: SelectedLedgerControlRequirements? = nil

		@PresentationState
		public var destination: Destinations.State? = nil

		var pendingAction: ActionRequiringP2P? = nil

		public init(allowSelection: Bool, showHeaders: Bool = true) {
			self.allowSelection = allowSelection
			self.showHeaders = showHeaders
		}
	}

	public enum ActionRequiringP2P: Sendable, Hashable {
		case addLedger
		case selectLedger(LedgerFactorSource)
	}

	// MARK: - Action

	public enum ViewAction: Sendable, Equatable {
		case onFirstTask
		case selectedLedger(id: FactorSource.ID?)
		case addNewLedgerButtonTapped
		case confirmedLedger(LedgerFactorSource)
		case whatIsALedgerButtonTapped
	}

	public enum InternalAction: Sendable, Equatable {
		case loadedLedgers(TaskResult<IdentifiedArrayOf<LedgerFactorSource>>)
		case hasAConnectorExtension(Bool)
		case perform(ActionRequiringP2P)
	}

	public enum ChildAction: Sendable, Equatable {
		case destination(PresentationAction<Destinations.Action>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case choseLedger(LedgerFactorSource)
	}

	// MARK: - Destination

	public struct Destinations: Sendable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case noP2PLink(AlertState<Action.NoP2PLinkAlert>)
			case addNewP2PLink(NewConnection.State)
			case addNewLedger(AddLedgerFactorSource.State)
		}

		public enum Action: Sendable, Equatable {
			case noP2PLink(NoP2PLinkAlert)
			case addNewP2PLink(NewConnection.Action)
			case addNewLedger(AddLedgerFactorSource.Action)

			public enum NoP2PLinkAlert: Sendable, Hashable {
				case addNewP2PLinkTapped
				case cancelTapped
			}
		}

		public var body: some ReducerProtocolOf<Self> {
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
	@Dependency(\.p2pLinksClient) var p2pLinksClient
	@Dependency(\.errorQueue) var errorQueue

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destinations()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .onFirstTask:
			return .merge(updateLedgersEffekt(state: &state), checkP2PLinkEffect())

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

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
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

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .destination(.presented(.noP2PLink(alertAction))):
			switch alertAction {
			case .addNewP2PLinkTapped:
				state.destination = .addNewP2PLink(.init())
				return .none

			case .cancelTapped:
				return .none
			}

		case let .destination(.presented(.addNewP2PLink(.delegate(newP2PAction)))):
			switch newP2PAction {
			case let .newConnection(connectedClient):
				state.destination = nil
				return .run { _ in
					try await p2pLinksClient.addP2PLink(connectedClient)
				} catch: { error, _ in
					loggerGlobal.error("Failed P2PLink, error \(error)")
					errorQueue.schedule(error)
				}

			case .dismiss:
				return .none
			}

		case let .destination(.presented(.addNewLedger(.delegate(newLedgerAction)))):
			switch newLedgerAction {
			case let .completed(ledger):
				state.destination = nil
				state.selectedLedgerID = ledger.id
				return updateLedgersEffekt(state: &state)
			case .dismiss:
				state.destination = nil
				return .none
			}

		default:
			return .none
		}
	}

	private func updateLedgersEffekt(state: inout State) -> EffectTask<Action> {
		state.$ledgers = .loading
		return .task {
			let result = await TaskResult {
				let ledgers = try await factorSourcesClient.getFactorSources(ofKind: .ledgerHQHardwareWallet)
					.compactMap { try? LedgerFactorSource(factorSource: $0) }
				return IdentifiedArray(uniqueElements: ledgers)
			}
			return .internal(.loadedLedgers(result))
		}
	}

	private func checkP2PLinkEffect() -> EffectTask<Action> {
		.run { send in
			for try await isConnected in await ledgerHardwareWalletClient.isConnectedToAnyConnectorExtension() {
				guard !Task.isCancelled else { return }
				await send(.internal(.hasAConnectorExtension(isConnected)))
			}
		} catch: { error, _ in
			loggerGlobal.error("failed to get links updates, error: \(error)")
		}
	}

	private func performActionRequiringP2PEffect(_ action: ActionRequiringP2P, in state: inout State) -> EffectTask<Action> {
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
			return .send(.delegate(.choseLedger(ledger)))
		}
	}
}

extension AlertState<LedgerHardwareDevices.Destinations.Action.NoP2PLinkAlert> {
	static var noP2Plink: Self {
		Self {
			TextState("Link a Connector") // FIXME: Strings
		} actions: {
			ButtonState(role: .cancel, action: .cancelTapped) {
				TextState(L10n.Common.cancel)
			}
			ButtonState(action: .addNewP2PLinkTapped) {
				TextState(L10n.Common.continue) // FIXME: Strings
			}
		} message: {
			TextState("To use a Ledger hardware wallet device, it must be connected to a computer running the Radix Connector browser extension.\n\nInstall the Connector extension, open it to see the linking QR code, and tap continue") // FIXME: Strings
		}
	}
}
