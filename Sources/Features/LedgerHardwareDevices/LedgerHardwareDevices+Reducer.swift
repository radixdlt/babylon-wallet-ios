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

		/// The action the user was planning when asked to first connect to a ConnectorExtension
		public var intendedAction: Intention? = nil

		public enum Intention: Sendable, Hashable {
			case addLedger
			case selectLedger(LedgerFactorSource)
		}

		public init(allowSelection: Bool, showHeaders: Bool = true) {
			self.allowSelection = allowSelection
			self.showHeaders = showHeaders
		}
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

		case hasAConnectorExtension(Bool, source: String)
		case fulfillIntention(State.Intention)
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

			public enum NoP2PLinkAlert: Sendable, Equatable {
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
//	@Dependency(\.radixConnectClient) var radixConnectClient
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
			return .merge(updateLedgersEffekt(state: &state),
			              checkP2PLinkEffect())
			//			return updateLedgersEffekt(state: &state)

		case let .selectedLedger(selectedID):
			state.selectedLedgerID = selectedID
			return .none

		case let .confirmedLedger(ledger):
			return fulfillEffect(state: &state, intention: .selectLedger(ledger))

		case .addNewLedgerButtonTapped:
			return fulfillEffect(state: &state, intention: .addLedger)

		case .whatIsALedgerButtonTapped:
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .loadedLedgers(result):
			state.$ledgers = .init(result: result)
			return .none
		case let .hasAConnectorExtension(isConnected, source):
			print("Is connected to any CE?: \(isConnected) \(source)")
//			loggerGlobal.notice("Is connected to any CE?: \(isConnected) \(source)")
			state.hasAConnectorExtension = isConnected
			return .none

		case let .fulfillIntention(intention):
			print("fulfillIntention")
			return fulfillEffect(state: &state, intention: intention)
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
				print("Setting intention to nil", state.intendedAction)
				state.intendedAction = nil
				return .none
			}

		case let .destination(.presented(.addNewP2PLink(.delegate(newP2PAction)))):
			switch newP2PAction {
			case let .newConnection(connectedClient):
				print("addNewP2PLink connectedClient")

				let intention = state.intendedAction
				state.destination = nil
				return .run { send in
					try await p2pLinksClient.addP2PLink(connectedClient)
					await send(.internal(.hasAConnectorExtension(true, source: "After connecting")))
					if let intention {
						// Continue what we were doing
						await send(.internal(.fulfillIntention(intention)))
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
				print("updateLedgersEffekt isConnected", isConnected)
				guard !Task.isCancelled else {
					print("updateLedgersEffekt task cancelled")
					return
				}

				print("updateLedgersEffekt sending connectivity")

				await send(.internal(.hasAConnectorExtension(isConnected, source: "task effect")))
			}
		} catch: { error, _ in
			loggerGlobal.error("failed to get links updates, error: \(error)")
		}
	}

	private func fulfillEffect(state: inout State, intention: State.Intention) -> EffectTask<Action> {
		print("fulfillEffect")
		// If we don't have a connection, we remember what we were trying to do and then ask if they want to link one
		guard state.hasAConnectorExtension else {
			print("fulfillEffect: No connection, do that first")
			state.intendedAction = intention
			state.destination = .noP2PLink(.noP2Plink)
			return .none
		}

		print("fulfillEffect: We have a connection")

		// If we have a connection, we can proceed directly
		state.intendedAction = nil
		switch intention {
		case .addLedger:
			state.destination = .addNewLedger(.init())
			return .none
		case let .selectLedger(ledger):
			print("fulfillEffect: choseLedger")

			return .send(.delegate(.choseLedger(ledger)))
		}
	}
}

extension AlertState<LedgerHardwareDevices.Destinations.Action.NoP2PLinkAlert> {
	static var noP2Plink: AlertState {
		AlertState {
			TextState("No connector!!") // FIXME: Strings
		} actions: {
			ButtonState(role: .cancel, action: .cancelTapped) {
				TextState(L10n.Common.cancel)
			}
			ButtonState(action: .addNewP2PLinkTapped) {
				TextState(L10n.Common.continue) // FIXME: Strings
			}
		} message: {
			TextState("You need to connect to a connector extension first") // FIXME: Strings
		}
	}
}
