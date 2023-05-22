import AddLedgerFactorSourceFeature
import FactorSourcesClient
import FeaturePrelude

// MARK: - LedgerHardwareWallets
public struct LedgerHardwareWallets: Sendable, FeatureReducer {
	@Dependency(\.factorSourcesClient) var factorSourcesClient

	// MARK: - State

	public struct State: Sendable, Hashable {
		@Loadable
		public var ledgers: [LedgerFactorSource]? = nil

		@PresentationState
		public var addNewLedger: AddLedgerFactorSource.State? = nil

		public init(ledgers: [LedgerFactorSource]? = nil, addNewLedger: AddLedgerFactorSource.State? = nil) {
			self.ledgers = ledgers
			self.addNewLedger = addNewLedger
		}
	}

	// MARK: - Action

	public enum ViewAction: Sendable, Equatable {
		case onFirstTask
		case addNewLedgerButtonTapped
	}

	public enum InternalAction: Sendable, Equatable {
		case loadedLedgers(TaskResult<[LedgerFactorSource]>)
	}

	public enum ChildAction: Sendable, Equatable {
		case addNewLedger(PresentationAction<AddLedgerFactorSource.Action>)
	}

	// MARK: - Reducer

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

		case .addNewLedgerButtonTapped:
			state.addNewLedger = .init()
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
		case .addNewLedger(.presented(.delegate(.completed))):
			state.addNewLedger = nil
			return updateLedgersEffekt(state: &state)

		default:
			return .none
		}
	}

	private func updateLedgersEffekt(state: inout State) -> EffectTask<Action> {
		state.$ledgers = .loading
		return .task {
			let result = await TaskResult {
				try await factorSourcesClient.getFactorSources(ofKind: .ledgerHQHardwareWallet)
					.compactMap { try? LedgerFactorSource(factorSource: $0) }
			}
			return .internal(.loadedLedgers(result))
		}
	}
}
