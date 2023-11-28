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
			case coordinator(ManualAccountRecoveryScanCoordinator.State)
		}

		public enum Action: Equatable, Sendable {
			case coordinator(ManualAccountRecoveryScanCoordinator.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(state: /State.coordinator, action: /Action.coordinator) {
				ManualAccountRecoveryScanCoordinator()
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

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			return .none

		case .babylonUseSeedPhraseTapped:
			state.destination = .coordinator(.chooseSeedPhrase)
			return .none

		case .babylonUseLedgerTapped:
			state.destination = .coordinator(.chooseLedger)
			return .none

		case .olympiaUseSeedPhraseTapped:
			return .none

		case .olympiaUseLedgerTapped:
			return .none
		}
	}
}

extension ManualAccountRecoveryScanCoordinator.State {
	static let chooseLedger: Self = .init(path: .init([.chooseLedger(.init())]))

	static let chooseSeedPhrase: Self = .init(path: .init([.chooseSeedPhrase(.init())]))
}
