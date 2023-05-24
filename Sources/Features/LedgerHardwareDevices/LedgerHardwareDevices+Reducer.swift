import AddLedgerFactorSourceFeature
import FactorSourcesClient
import FeaturePrelude
import Profile

// MARK: - LedgerHardwareDevicesCoordinator
public struct LedgerHardwareDevicesCoordinator: Sendable, FeatureReducer {
	// MARK: - State

	public struct State: Sendable, Hashable {
		@PresentationState
		public var destination: Destinations.State? = nil

		public init(destination: Destinations.State? = nil) {
			self.destination = destination
		}
	}

	// MARK: - Action

	public enum ChildAction: Sendable, Equatable {
		case destination(PresentationAction<Destinations.Action>)
	}

	public enum ViewAction: Sendable, Equatable {
		case onFirstTask
	}

	// MARK: - Destination

	public struct Destinations: Sendable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case selectDevice(LedgerHardwareDevices.State)
		}

		public enum Action: Sendable, Equatable {
			case linkConnector(LedgerHardwareDevicesLinkConnector.Action)
			case selectDevice(LedgerHardwareDevices.Action)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.linkConnector, action: /Action.linkConnector) {
				LedgerHardwareDevicesLinkConnector()
			}
			Scope(state: /State.selectDevice, action: /Action.selectDevice) {
				LedgerHardwareDevices()
			}
		}
	}

	// MARK: - Reducer

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destinations()
			}
	}
}

import NewConnectionFeature

// MARK: - LedgerHardwareDevicesLinkConnector
public struct LedgerHardwareDevicesLinkConnector: Sendable, FeatureReducer {
	// MARK: - State

	public struct State: Sendable, Hashable {
		@PresentationState
		var destination: Destinations.State? = nil
	}

	// MARK: - Action

	public enum ChildAction: Sendable, Equatable {
		case destination(PresentationAction<Destinations.Action>)
	}

	public enum ViewAction: Sendable, Equatable {
		case onFirstTask
		case addConnectorButtonTapped
	}

	// MARK: - Destination

	public struct Destinations: Sendable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case addNewP2PLink(NewConnection.State)
		}

		public enum Action: Sendable, Equatable {
			case addNewP2PLink(NewConnection.Action)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.addNewP2PLink, action: /Action.addNewP2PLink) {
				NewConnection()
			}
		}
	}

	// MARK: - Reducer

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
			return .none

		case .addConnectorButtonTapped:
			state.destination = .addNewP2PLink(.init())
			return .none
		}
	}
}

// MARK: - SelectedLedgerControlRequirements
struct SelectedLedgerControlRequirements: Hashable {
	let selectedLedger: LedgerFactorSource
}

// MARK: - LedgerHardwareDevices
public struct LedgerHardwareDevices: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let allowSelection: Bool
		public let showHeaders: Bool

		@Loadable
		public var ledgers: IdentifiedArrayOf<LedgerFactorSource>? = nil

		public var selectedLedgerID: FactorSourceID? = nil
		let selectedLedgerControlRequirements: SelectedLedgerControlRequirements? = nil

		@PresentationState
		public var addNewLedger: AddLedgerFactorSource.State?

		public init(allowSelection: Bool, showHeaders: Bool = true) {
			self.allowSelection = allowSelection
			self.showHeaders = showHeaders
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case onFirstTask
		case selectedLedger(id: FactorSource.ID?)
		case addNewLedgerButtonTapped
		case confirmedLedger(LedgerFactorSource)
		case whatIsALedgerButtonTapped
	}

	public enum InternalAction: Sendable, Equatable {
		case loadedLedgers(TaskResult<IdentifiedArrayOf<LedgerFactorSource>>)
	}

	public enum ChildAction: Sendable, Equatable {
		case addNewLedger(PresentationAction<AddLedgerFactorSource.Action>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case choseLedger(LedgerFactorSource)
	}

	@Dependency(\.factorSourcesClient) var factorSourcesClient

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(\.$addNewLedger, action: /Action.child .. ChildAction.addNewLedger) {
				AddLedgerFactorSource()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .onFirstTask:
			return updateLedgersEffekt(state: &state)

		case let .selectedLedger(selectedID):
			state.selectedLedgerID = selectedID
			return .none

		case .addNewLedgerButtonTapped:
			state.addNewLedger = .init()
			return .none

		case let .confirmedLedger(ledger):
			return .send(.delegate(.choseLedger(ledger)))

		case .whatIsALedgerButtonTapped:
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .loadedLedgers(result):
			state.$ledgers = .init(result: result)
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .addNewLedger(.presented(.delegate(.completed(ledger, _)))):
			state.addNewLedger = nil
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
}
