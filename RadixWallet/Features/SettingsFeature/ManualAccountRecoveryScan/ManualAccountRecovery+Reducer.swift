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
		case useSeedPhraseTapped(isOlympia: Bool)
		case useLedgerTapped(isOlympia: Bool)
	}

	public enum DelegateAction: Sendable, Equatable {
		case gotoAccountList
	}

	@Dependency(\.dismiss) var dismiss

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

		case let .useSeedPhraseTapped(isOlympia):
			state.destination = .seedPhrase(.init(isOlympia: isOlympia))
			return .none

		case let .useLedgerTapped(isOlympia):
			state.destination = .ledger(.init(isOlympia: isOlympia))
			return .none
		}
	}

	public func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case .seedPhrase(.delegate(.gotoAccountList)), .ledger(.delegate(.gotoAccountList)):
			.run { send in
				await send(.delegate(.gotoAccountList))
			}

		default:
			.none
		}
	}
}
