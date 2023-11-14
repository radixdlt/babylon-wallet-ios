import ComposableArchitecture
import SwiftUI

// MARK: - SelectFactorKindThenFactor
public struct SelectFactorKindThenFactor: Sendable, FeatureReducer {
	// MARK: State

	public struct State: Sendable, Hashable {
		public let role: SecurityStructureRole

		@PresentationState
		public var destination: Destination.State? = nil

		public init(role: SecurityStructureRole) {
			self.role = role
		}
	}

	// MARK: Action

	public enum ViewAction: Sendable, Equatable {
		case selected(FactorSourceKind)
	}

	public enum DelegateAction: Sendable, Equatable {
		case selected(FactorSource)
	}

	// MARK: Destination

	public struct Destination: DestinationReducer {
		public enum State: Hashable, Sendable {
			case factorSourceOfKind(FactorSourcesOfKindList<FactorSource>.State)
			// Uh... we have to special treat Ledger, because... it is complex and uses its own list because
			// it requires P2P connection...
			case selectLedger(LedgerHardwareDevices.State)
		}

		public enum Action: Equatable, Sendable {
			case factorSourceOfKind(FactorSourcesOfKindList<FactorSource>.Action)
			case selectLedger(LedgerHardwareDevices.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(state: /State.factorSourceOfKind, action: /Action.factorSourceOfKind) {
				FactorSourcesOfKindList<FactorSource>()
			}
			Scope(state: /State.selectLedger, action: /Action.selectLedger) {
				LedgerHardwareDevices()
			}
		}
	}

	// MARK: Reducer

	public init() {}

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case let .selected(kind):
			switch kind {
			case .ledgerHQHardwareWallet:
				state.destination = .selectLedger(.init(context: .setupMFA))
			default:
				state.destination = .factorSourceOfKind(.init(kind: kind, mode: .selection))
			}
			return .none
		}
	}

	public func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case let .factorSourceOfKind(.delegate(.choseFactorSource(factorSource))):
			state.destination = nil
			return .send(.delegate(.selected(factorSource)))

		case let .selectLedger(.delegate(.choseLedger(ledger))):
			state.destination = nil
			return .send(.delegate(.selected(ledger.embed())))

		default:
			return .none
		}
	}
}
