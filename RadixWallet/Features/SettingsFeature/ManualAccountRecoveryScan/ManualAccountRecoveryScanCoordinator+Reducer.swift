import ComposableArchitecture
import SwiftUI

public struct ManualAccountRecoveryScanCoordinator: Sendable, FeatureReducer {
	public typealias Store = StoreOf<Self>

	public struct State: Sendable, Hashable {
		public var path: StackState<Path.State> = .init()
	}

	public struct Path: Sendable, Hashable, Reducer {
		public enum State: Sendable, Hashable {
			case selectInactiveAccountsToAdd(SelectInactiveAccountsToAdd.State)
		}

		public enum Action: Sendable, Equatable {
			case selectInactiveAccountsToAdd(SelectInactiveAccountsToAdd.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(state: /State.selectInactiveAccountsToAdd, action: /Action.selectInactiveAccountsToAdd) {
				SelectInactiveAccountsToAdd()
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

	public enum ChildAction: Sendable, Equatable {
		case path(StackActionOf<Path>)
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .path(.element(id: id, action: pathAction)):
			reduce(into: &state, id: id, pathAction: pathAction)
		case let .path(.popFrom(id: id)):
			.none
		case let .path(.push(id: id, state: pathState)):
			.none
		}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			.none

		case .babylonUseSeedPhraseTapped:
			.none

		case .babylonUseLedgerTapped:
			.none

		case .olympiaUseSeedPhraseTapped:
			.none

		case .olympiaUseLedgerTapped:
			.none
		}
	}

	public func reduce(into state: inout State, id: StackElementID, pathAction: Path.Action) -> Effect<Action> {
//		switch pathAction {
//		}
		.none
	}
}
