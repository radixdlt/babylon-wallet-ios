import ComposableArchitecture
import SwiftUI

// MARK: - ManualAccountRecoveryLedgerCoordinator
public struct ManualAccountRecoveryLedgerCoordinator: Sendable, FeatureReducer {
	public typealias Store = StoreOf<Self>

	// MARK: - State

	public struct State: Sendable, Hashable {
		public var isOlympia: Bool
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

	public enum DelegateAction: Sendable, Equatable {
		case gotoAccountList
	}

	// MARK: - Path

	public struct Path: Sendable, Hashable, Reducer {
		@CasePathable
		public enum State: Sendable, Hashable {
			case accountRecoveryScan(AccountRecoveryScanCoordinator.State)
			case recoveryComplete(ManualAccountRecoveryCompletion.State)
		}

		@CasePathable
		public enum Action: Sendable, Equatable {
			case accountRecoveryScan(AccountRecoveryScanCoordinator.Action)
			case recoveryComplete(ManualAccountRecoveryCompletion.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(state: \.accountRecoveryScan, action: \.accountRecoveryScan) {
				AccountRecoveryScanCoordinator()
			}
			Scope(state: \.recoveryComplete, action: \.recoveryComplete) {
				ManualAccountRecoveryCompletion()
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
		default:
			.none
		}
	}

	private func reduce(into state: inout State, rootAction: LedgerHardwareDevices.Action) -> Effect<Action> {
		switch rootAction {
		case let .delegate(.choseLedger(ledger)):
			state.showAccountRecoveryScan(factorSourceID: ledger.id)
			return .none

		default:
			return .none
		}
	}

	private func reduce(into state: inout State, id: StackElementID, pathAction: Path.Action) -> Effect<Action> {
		switch pathAction {
		case .accountRecoveryScan(.delegate(.dismissed)):
			_ = state.path.popLast()
			return .none

		case .accountRecoveryScan(.delegate(.completed)):
			_ = state.path.popLast()
			state.path.append(.recoveryComplete(.init()))
			return .none

		case let .recoveryComplete(.delegate(recoveryCompleteAction)):
			switch recoveryCompleteAction {
			case .finish:
				return .run { send in
					await send(.delegate(.gotoAccountList))
				}
			}

		default:
			return .none
		}
	}
}

private extension ManualAccountRecoveryLedgerCoordinator.State {
	mutating func showAccountRecoveryScan(factorSourceID: FactorSourceID.FromHash) {
		path.append(.accountRecoveryScan(.init(
			purpose: .addAccounts(factorSourceID: factorSourceID, olympia: isOlympia)
		)))
	}
}
