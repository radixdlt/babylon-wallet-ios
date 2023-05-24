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

		public init(allowSelection: Bool, showHeaders: Bool = true) {
			self.allowSelection = allowSelection
			self.showHeaders = showHeaders
		}
	}

	public enum Intent: Sendable, Hashable {
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
		case fulfillIntent(Intent)
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
			case addNewP2PLink(NewConnection.State, andThen: Intent)
			case addNewLedger(AddLedgerFactorSource.State)

			public var intent: Intent? {
				guard case let .addNewP2PLink(_, andThen: intent) = self else { return nil }
				return intent
			}
		}

		public enum Action: Sendable, Equatable {
			case noP2PLink(NoP2PLinkAlert)
			case addNewP2PLink(NewConnection.Action)
			case addNewLedger(AddLedgerFactorSource.Action)

			public enum NoP2PLinkAlert: Sendable, Hashable {
				case addNewP2PLinkTapped(Intent)
				case cancelTapped
			}
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.addNewP2PLink, action: /Action.addNewP2PLink) {
				Scope(state: \.0, action: /.self) {
					NewConnection()
				}
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
			return fulfillEffect(state: &state, intent: .selectLedger(ledger))

		case .addNewLedgerButtonTapped:
			return fulfillEffect(state: &state, intent: .addLedger)

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
			return .none

		case let .fulfillIntent(intent):
			return fulfillEffect(state: &state, intent: intent)
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .destination(.presented(.noP2PLink(alertAction))):
			switch alertAction {
			case let .addNewP2PLinkTapped(intent: intent):
				state.destination = .addNewP2PLink(.init(), andThen: intent)
				return .none

			case .cancelTapped:
				return .none
			}

		case let .destination(.presented(.addNewP2PLink(.delegate(newP2PAction)))):
			switch newP2PAction {
			case let .newConnection(connectedClient):
				let intent = state.destination?.intent
				state.destination = nil
				return .run { send in
					try await p2pLinksClient.addP2PLink(connectedClient)
					await send(.internal(.hasAConnectorExtension(true)))
					if let intent {
						// Continue what we were doing
						await send(.internal(.fulfillIntent(intent)))
					}
				} catch: { error, _ in
					loggerGlobal.error("Failed P2PLink, error \(error)")
					errorQueue.schedule(error)
				}

			case .dismiss:
				return .none
			}

		case let .destination(.presented(.addNewLedger(.delegate(.completed(ledger: ledger, isNew: _))))):
			state.destination = nil
			state.selectedLedgerID = ledger.id
			return updateLedgersEffekt(state: &state)

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

	private func fulfillEffect(state: inout State, intent: Intent) -> EffectTask<Action> {
		// If we don't have a connection, we remember what we were trying to do and then ask if they want to link one
		guard state.hasAConnectorExtension else {
			state.destination = .noP2PLink(.noP2Plink(intent: intent))
			return .none
		}

		// If we have a connection, we can proceed directly
		switch intent {
		case .addLedger:
			state.destination = .addNewLedger(.init())
			return .none
		case let .selectLedger(ledger):
			return .send(.delegate(.choseLedger(ledger)))
		}
	}
}

extension AlertState<LedgerHardwareDevices.Destinations.Action.NoP2PLinkAlert> {
	static func noP2Plink(intent: LedgerHardwareDevices.Intent) -> AlertState {
		AlertState {
			TextState("No connector!!") // FIXME: Strings
		} actions: {
			ButtonState(role: .cancel, action: .cancelTapped) {
				TextState(L10n.Common.cancel)
			}
			ButtonState(action: .addNewP2PLinkTapped(intent)) {
				TextState(L10n.Common.continue) // FIXME: Strings
			}
		} message: {
			TextState("You need to connect to a connector extension first") // FIXME: Strings
		}
	}
}
