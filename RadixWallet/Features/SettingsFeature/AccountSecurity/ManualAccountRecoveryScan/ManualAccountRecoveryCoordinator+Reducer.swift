import ComposableArchitecture
import SwiftUI

// MARK: - ManualAccountRecoveryCoordinator
public struct ManualAccountRecoveryCoordinator: Sendable, FeatureReducer {
	public typealias Store = StoreOf<Self>

	public struct State: Sendable, Hashable {
		public var path: StackState<Path.State> = .init()
		public var isMainnet: Bool = false

		public init() {}
	}

	// MARK: - Path

	public struct Path: Sendable, Hashable, Reducer {
		@CasePathable
		public enum State: Sendable, Hashable {
			case seedPhrase(ManualAccountRecoverySeedPhrase.State)
			case ledger(LedgerHardwareDevices.State)

			case accountRecoveryScan(AccountRecoveryScanCoordinator.State)
			case recoveryComplete(RecoverWalletControlWithBDFSComplete.State)
		}

		@CasePathable
		public enum Action: Sendable, Equatable {
			case seedPhrase(ManualAccountRecoverySeedPhrase.Action)
			case ledger(LedgerHardwareDevices.Action)

			case accountRecoveryScan(AccountRecoveryScanCoordinator.Action)
			case recoveryComplete(RecoverWalletControlWithBDFSComplete.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(state: \.seedPhrase, action: \.seedPhrase) {
				ManualAccountRecoverySeedPhrase()
			}
			Scope(state: \.ledger, action: \.ledger) {
				LedgerHardwareDevices()
			}
			Scope(state: \.accountRecoveryScan, action: \.accountRecoveryScan) {
				AccountRecoveryScanCoordinator()
			}
			Scope(state: \.recoveryComplete, action: \.recoveryComplete) {
				RecoverWalletControlWithBDFSComplete()
			}
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case closeButtonTapped
		case useSeedPhraseTapped(isOlympia: Bool)
		case useLedgerTapped(isOlympia: Bool)
	}

	public enum ChildAction: Sendable, Equatable {
		case path(StackActionOf<Path>)
	}

	public enum InternalAction: Sendable, Equatable {
		case isMainnet(Bool)
	}

	public enum DelegateAction: Sendable, Equatable {
		case gotoAccountList
	}

	@Dependency(\.dismiss) var dismiss
	@Dependency(\.gatewaysClient) var gatewaysClient

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.forEach(\.path, action: /Action.child .. ChildAction.path) {
				Path()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			return .run { send in
				let isMainnet = await gatewaysClient.getCurrentGateway().network == .mainnet
				await send(.internal(.isMainnet(isMainnet)))
			}

		case .closeButtonTapped:
			return .run { _ in await dismiss() }

		case let .useSeedPhraseTapped(isOlympia):
			state.path = .init([.seedPhrase(.init(isOlympia: isOlympia))])
			return .none

		case let .useLedgerTapped(isOlympia):
			state.path = .init([.ledger(.init(context: .accountRecovery(olympia: isOlympia)))])
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .path(.element(id: id, action: pathAction)):
			reduce(into: &state, id: id, pathAction: pathAction)
		default:
			.none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .isMainnet(isMainnet):
			state.isMainnet = isMainnet
			return .none
		}
	}

	private func reduce(into state: inout State, id: StackElementID, pathAction: Path.Action) -> Effect<Action> {
		switch pathAction {
		case let .seedPhrase(.delegate(.recover(factorSourceID, isOlympia))):
			state.path.append(.accountRecoveryScan(.init(purpose: .addAccounts(factorSourceID: factorSourceID, olympia: isOlympia))))
			return .none

		case let .ledger(.delegate(.choseLedgerForRecovery(ledger, isOlympia: isOlympia))):
			state.path.append(.accountRecoveryScan(.init(purpose: .addAccounts(factorSourceID: ledger.id, olympia: isOlympia))))
			return .none

		case .accountRecoveryScan(.delegate(.dismissed)):
			_ = state.path.popLast()
			return .none

		case .accountRecoveryScan(.delegate(.completed)):
			state.path.append(.recoveryComplete(.init()))
			return .none

		case .recoveryComplete(.delegate(.profileCreatedFromImportedBDFS)):
			return .run { send in
				await send(.delegate(.gotoAccountList))
			}

		default:
			return .none
		}
	}
}
