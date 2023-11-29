import ComposableArchitecture
import SwiftUI

// MARK: - ManualAccountRecovery
public struct ManualAccountRecovery: Sendable, FeatureReducer {
	public typealias Store = StoreOf<Self>

	public struct State: Sendable, Hashable {
		@PresentationState
		var destination: Destination.State? = nil
	}

	// MARK: - Destination

	public struct Destination: DestinationReducer {
		public enum State: Hashable, Sendable {
			case seedPhrase(ManualAccountRecoverySeedPhraseCoordinator.State)
			case ledger(ManualAccountRecoveryLedgerCoordinator.State)
		}

		public enum Action: Equatable, Sendable {
			case seedPhrase(ManualAccountRecoverySeedPhraseCoordinator.Action)
			case ledger(ManualAccountRecoveryLedgerCoordinator.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(state: /State.seedPhrase, action: /Action.seedPhrase) {
				ManualAccountRecoverySeedPhraseCoordinator()
			}
			Scope(state: /State.ledger, action: /Action.ledger) {
				ManualAccountRecoveryLedgerCoordinator()
			}
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case babylonUseSeedPhraseTapped
		case babylonUseLedgerTapped
		case olympiaUseSeedPhraseTapped
		case olympiaUseLedgerTapped
	}

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			return .none

		case .babylonUseSeedPhraseTapped:
			state.destination = .seedPhrase(.init())
			return .none

		case .babylonUseLedgerTapped:
			state.destination = .ledger(.init())
			return .none

		case .olympiaUseSeedPhraseTapped:
			return .none

		case .olympiaUseLedgerTapped:
			return .none
		}
	}

	public func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case let .seedPhrase(.delegate(seedPhraseAction)):
			switch seedPhraseAction {}

		case let .ledger(.delegate(ledgerAction)):
			switch ledgerAction {}

		default:
			return .none
		}
	}
}
