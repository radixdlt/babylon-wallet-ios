import AddLedgerFactorSourceFeature
import FeaturePrelude
import Profile

// MARK: - SelectedLedgerControlRequirements
struct SelectedLedgerControlRequirements: Hashable {
	let selectedLedger: LedgerFactorSource
}

// MARK: - ChooseLedgerHardwareDevice
public struct ChooseLedgerHardwareDevice: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		var ledgers: IdentifiedArrayOf<LedgerFactorSource> = []
		var selectedLedgerID: FactorSourceID? = nil
		let selectedLedgerControlRequirements: SelectedLedgerControlRequirements? = nil

		@PresentationState
		public var addNewLedger: AddLedgerFactorSource.State?

		public init() {}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case selectedLedger(id: FactorSource.ID?)
		case addNewLedgerButtonTapped
		case confirmedLedger(LedgerFactorSource)
	}

	public enum ChildAction: Sendable, Equatable {
		case addNewLedger(PresentationAction<AddLedgerFactorSource.Action>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case choseLedger(LedgerFactorSource)
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
			fatalError()
//			switch state.genesisFactorSourceSelection {
//			case let .device(babylonDeviceFactorSource):
//				return createEntityControlledByDeviceFactorSource(babylonDeviceFactorSource, state: state)
//			case let .ledger(ledgers):
//				precondition(ledgers.allSatisfy { $0.kind == .ledgerHQHardwareWallet })
//				state.ledgers = IdentifiedArrayOf<FactorSource>.init(uniqueElements: ledgers, id: \.id)
//				if let first = ledgers.first {
//					state.selectedLedgerID = first.id
//				}
//				return .none
//			}
		case let .selectedLedger(selectedID):
			state.selectedLedgerID = selectedID
			return .none

		case .addNewLedgerButtonTapped:
			state.addNewLedger = .init()
			return .none

		case let .confirmedLedger(ledger):
			return .send(.delegate(.choseLedger(ledger)))
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
