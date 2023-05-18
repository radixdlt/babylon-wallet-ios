import AddLedgerFactorSourceFeature
import FeaturePrelude

// MARK: - ChoseLedgerHardwareDevice
public struct ChoseLedgerHardwareDevice: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		let ledgers: IdentifiedArrayOf<FactorSource>
		var ledgersArray: [FactorSource]? { .init(ledgers) }
		let selectedLedgerID: FactorSourceID?
		let selectedLedgerControlRequirements: SelectedLedgerControlRequirements?

		@PresentationState
		public var addNewLedger: AddLedgerFactorSource.State?

		public init() {}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case selectedLedger(id: FactorSource.ID?)
		case addNewLedgerButtonTapped
		case confirmedLedger(FactorSource)
	}

	public enum ChildAction: Sendable, Equatable {
		case addNewLedger(PresentationAction<AddLedgerFactorSource.Action>)
	}

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(\.$addNewLedger, action: /Action.child .. ChildAction.addNewLedger) {
				AddLedgerFactorSource()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			switch state.genesisFactorSourceSelection {
			case let .device(babylonDeviceFactorSource):
				return createEntityControlledByDeviceFactorSource(babylonDeviceFactorSource, state: state)
			case let .ledger(ledgers):
				precondition(ledgers.allSatisfy { $0.kind == .ledgerHQHardwareWallet })
				state.ledgers = IdentifiedArrayOf<FactorSource>.init(uniqueElements: ledgers, id: \.id)
				if let first = ledgers.first {
					state.selectedLedgerID = first.id
				}
				return .none
			}
		case let .selectedLedger(selectedID):
			state.selectedLedgerID = selectedID
			return .none

		case .addNewLedgerButtonTapped:
			state.addNewLedger = .init()
			return .none

		case let .confirmedLedger(ledger):
			return sendDerivePublicKeyRequest(ledger, state: state)
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .addNewLedger(.presented(.delegate(.completed(ledger)))):
			state.addNewLedger = nil
			state.selectedLedgerID = ledger.id
			state.ledgers[id: ledger.id] = ledger
			return .none

		default:
			return .none
		}
	}
}
