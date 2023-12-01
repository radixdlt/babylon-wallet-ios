import ComposableArchitecture
import SwiftUI

// MARK: - ManualAccountRecoveryLedgerCoordinator
public struct ManualAccountRecoveryLedgerCoordinator: Sendable, FeatureReducer {
	public typealias Store = StoreOf<Self>

	// MARK: - State

	public struct State: Sendable, Hashable {
		public var accountType: ManualAccountRecovery.AccountType
		public var root: LedgerHardwareDevices.State = .init(context: .accountRecovery)
		public var path: StackState<Path.State> = .init()
	}

	// MARK: - Action

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case closeButtonTapped
	}

	public enum ChildAction: Sendable, Equatable {
		case root(LedgerHardwareDevices.Action)
		case path(StackActionOf<Path>)
	}

	// MARK: - Path

	public struct Path: Sendable, Hashable, Reducer {
		public enum State: Sendable, Hashable {
			case recoveryComplete(ManualAccountRecoveryComplete.State)
		}

		public enum Action: Sendable, Equatable {
			case recoveryComplete(ManualAccountRecoveryComplete.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(state: /State.recoveryComplete, action: /Action.recoveryComplete) {
				ManualAccountRecoveryComplete()
			}
		}
	}

	// MARK: - Reducer

	@Dependency(\.dismiss) var dismiss

	public var body: some ReducerOf<Self> {
		Scope(state: \.root, action: /Action.child .. ChildAction.root) {
			LedgerHardwareDevices()
		}
		Reduce(core)
			.forEach(\.path, action: /Action.child .. ChildAction.path) {
				Path()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			.none

		case .closeButtonTapped:
			.run { _ in await dismiss() }
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .root(rootAction):
			reduce(into: &state, rootAction: rootAction)
		case let .path(.element(id: id, action: pathAction)):
			reduce(into: &state, id: id, pathAction: pathAction)
		case let .path(.popFrom(id: id)):
			.none
		case let .path(.push(id: id, state: pathState)):
			.none
		}
	}

	private func reduce(into state: inout State, rootAction: LedgerHardwareDevices.Action) -> Effect<Action> {
		switch rootAction {
		case let .delegate(.choseLedger(ledger)):
			.none

		default:
			.none
		}
	}

	private func reduce(into state: inout State, id: StackElementID, pathAction: Path.Action) -> Effect<Action> {
//		switch pathAction {
//		}
		.none
	}
}
