import ComposableArchitecture
import SwiftUI

// MARK: - ManualAccountRecoveryCoordinator
struct ManualAccountRecoveryCoordinator: Sendable, FeatureReducer {
	typealias Store = StoreOf<Self>

	struct State: Sendable, Hashable {
		var path: StackState<Path.State> = .init()
		var isMainnet: Bool = false
		var isOlympia: Bool = false

		init() {}
	}

	// MARK: - Path

	struct Path: Sendable, Hashable, Reducer {
		@CasePathable
		enum State: Sendable, Hashable {
			case selectFactorSource(FactorSourcesList.State)

			case accountRecoveryScan(AccountRecoveryScanCoordinator.State)
			case recoveryComplete(RecoverWalletControlWithBDFSComplete.State)
		}

		@CasePathable
		enum Action: Sendable, Equatable {
			case selectFactorSource(FactorSourcesList.Action)

			case accountRecoveryScan(AccountRecoveryScanCoordinator.Action)
			case recoveryComplete(RecoverWalletControlWithBDFSComplete.Action)
		}

		var body: some ReducerOf<Self> {
			Scope(state: \.selectFactorSource, action: \.selectFactorSource) {
				FactorSourcesList()
			}
			Scope(state: \.accountRecoveryScan, action: \.accountRecoveryScan) {
				AccountRecoveryScanCoordinator()
			}
			Scope(state: \.recoveryComplete, action: \.recoveryComplete) {
				RecoverWalletControlWithBDFSComplete()
			}
		}
	}

	enum ViewAction: Sendable, Equatable {
		case appeared
		case closeButtonTapped
		case useSeedPhraseTapped(isOlympia: Bool)
		case useLedgerTapped(isOlympia: Bool)
	}

	enum ChildAction: Sendable, Equatable {
		case path(StackActionOf<Path>)
	}

	enum InternalAction: Sendable, Equatable {
		case isMainnet(Bool)
	}

	enum DelegateAction: Sendable, Equatable {
		case gotoAccountList
	}

	@Dependency(\.dismiss) var dismiss
	@Dependency(\.gatewaysClient) var gatewaysClient

	var body: some ReducerOf<Self> {
		Reduce(core)
			.forEach(\.path, action: /Action.child .. ChildAction.path) {
				Path()
			}
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			return .run { send in
				let isMainnet = await gatewaysClient.getCurrentGateway().network.id == .mainnet
				await send(.internal(.isMainnet(isMainnet)))
			}

		case .closeButtonTapped:
			return .run { _ in await dismiss() }

		case let .useSeedPhraseTapped(isOlympia):
			state.isOlympia = isOlympia
			state.path = .init([.selectFactorSource(.init(context: .selection(.authenticationSigning), kind: .device))])
			return .none

		case let .useLedgerTapped(isOlympia):
			state.isOlympia = isOlympia
			state.path = .init([.selectFactorSource(.init(context: .selection(.authenticationSigning), kind: .ledgerHqHardwareWallet))])
			return .none
		}
	}

	func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .path(.element(id: id, action: pathAction)):
			reduce(into: &state, id: id, pathAction: pathAction)
		default:
			.none
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .isMainnet(isMainnet):
			state.isMainnet = isMainnet
			return .none
		}
	}

	private func reduce(into state: inout State, id: StackElementID, pathAction: Path.Action) -> Effect<Action> {
		switch pathAction {
		case let .selectFactorSource(.delegate(.selectedFactorSource(source))):
			switch source.factorSourceID {
			case let .hash(value):
				state.path.append(.accountRecoveryScan(.init(purpose: .addAccounts(factorSourceID: value, olympia: state.isOlympia))))
			}
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
