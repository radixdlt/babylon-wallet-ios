import FeaturePrelude
import LedgerHardwareDevicesFeature

// MARK: - SelectFactorKindThenFactor
public struct SelectFactorKindThenFactor: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let role: SecurityStructureRole

		@PresentationState
		public var factorSourceOfKind: FactorSourcesOfKindList<FactorSource>.State?

		// Uh... we have to special treat Ledger, because... it is complex and uses its own list because
		// it requires P2P connection...
		@PresentationState
		public var selectLedger: LedgerHardwareDevices.State?

		public init(role: SecurityStructureRole) {
			self.role = role
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case selected(FactorSourceKind)
	}

	public enum ChildAction: Sendable, Equatable {
		case factorSourceOfKind(PresentationAction<FactorSourcesOfKindList<FactorSource>.Action>)
		case selectLedger(PresentationAction<LedgerHardwareDevices.Action>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case selected(FactorSource)
	}

	public init() {}

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(\.$factorSourceOfKind, action: /Action.child .. ChildAction.factorSourceOfKind) {
				FactorSourcesOfKindList<FactorSource>()
			}
			.ifLet(\.$selectLedger, action: /Action.child .. ChildAction.selectLedger) {
				LedgerHardwareDevices()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case let .selected(kind):
			switch kind {
			case .ledgerHQHardwareWallet:
				state.selectLedger = .init(context: .setupMFA)
			default:
				state.factorSourceOfKind = .init(kind: kind, mode: .selection)
			}
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .factorSourceOfKind(.presented(.delegate(.choseFactorSource(factorSource)))):
			state.factorSourceOfKind = nil
			return .send(.delegate(.selected(factorSource)))

		case let .selectLedger(.presented(.delegate(.choseLedger(ledger)))):
			state.selectLedger = nil
			return .send(.delegate(.selected(ledger.embed())))

		default:
			return .none
		}
	}
}
