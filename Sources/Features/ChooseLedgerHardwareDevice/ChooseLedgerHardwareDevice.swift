import AddLedgerFactorSourceFeature
import FactorSourcesClient
import FeaturePrelude
import Profile

// MARK: - SelectedLedgerControlRequirements
struct SelectedLedgerControlRequirements: Hashable {
	let selectedLedger: LedgerFactorSource
}

// MARK: - ChooseLedgerHardwareDevice
public struct ChooseLedgerHardwareDevice: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var ledgers: IdentifiedArrayOf<LedgerFactorSource> = []
		public var selectedLedgerID: FactorSourceID? = nil
		let selectedLedgerControlRequirements: SelectedLedgerControlRequirements? = nil

		@PresentationState
		public var addNewLedger: AddLedgerFactorSource.State?

		public init() {}
	}

	public enum ViewAction: Sendable, Equatable {
		case onFirstTask
		case selectedLedger(id: FactorSource.ID?)
		case addNewLedgerButtonTapped
		case confirmedLedger(LedgerFactorSource)
	}

	public enum InternalAction: Sendable, Equatable {
		case loadedLedgers(IdentifiedArrayOf<LedgerFactorSource>)
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
			return .task {
				let ledgers = try await factorSourcesClient.getFactorSources(ofKind: .ledgerHQHardwareWallet).compactMap {
					try? LedgerFactorSource(factorSource: $0)
				}
				return .internal(.loadedLedgers(.init(uniqueElements: ledgers)))
			}

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

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .loadedLedgers(ledgers):
			state.ledgers = ledgers
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .addNewLedger(.presented(.delegate(.completed(ledger, _)))):
			state.addNewLedger = nil
			state.selectedLedgerID = ledger.id
			state.ledgers[id: ledger.id] = ledger
			return .none

		default:
			return .none
		}
	}
}
