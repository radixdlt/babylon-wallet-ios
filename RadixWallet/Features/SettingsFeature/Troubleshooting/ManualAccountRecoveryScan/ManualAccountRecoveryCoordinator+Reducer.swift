import ComposableArchitecture
import SwiftUI

// MARK: - ManualAccountRecoveryCoordinator
@Reducer
struct ManualAccountRecoveryCoordinator: Sendable, FeatureReducer {
	typealias Store = StoreOf<Self>

	@ObservableState
	struct State: Sendable, Hashable {
		var path: StackState<Path.State> = .init()
		var isMainnet: Bool = false

		init() {}
	}

	typealias Action = FeatureAction<Self>

	// MARK: - Path

	@Reducer(state: .hashable, action: .equatable)
	enum Path {
		case selectFactorSource(SelectFactorSource)
		case accountRecoveryScan(AccountRecoveryScanCoordinator)
		case recoveryComplete(RecoverWalletControlWithBDFSComplete)
	}

	enum ViewAction: Sendable, Equatable {
		case appeared
		case closeButtonTapped
		case recoverBabylonAccountsTapped
		case recoverOlympiaAccountsTapped
	}

	@CasePathable
	enum ChildAction: Sendable, Equatable {
		case path(StackActionOf<Path>)
	}

	enum InternalAction: Sendable, Equatable {
		case isMainnet(Bool)
	}

	enum DelegateAction: Sendable, Equatable {
		case completed
	}

	@Dependency(\.dismiss) var dismiss
	@Dependency(\.gatewaysClient) var gatewaysClient

	var body: some ReducerOf<Self> {
		Reduce(core)
			.forEach(\.path, action: \.child.path)
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

		case .recoverBabylonAccountsTapped:
			state.path.append(.selectFactorSource(.init(context: .accountRecovery(isOlympia: false))))
			return .none

		case .recoverOlympiaAccountsTapped:
			state.path.append(.selectFactorSource(.init(context: .accountRecovery(isOlympia: true))))
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
		case let .selectFactorSource(.delegate(.selectedFactorSource(fs, context))):
			let isOlympiaRecovery = switch context {
			case let .accountRecovery(isOlympia):
				isOlympia
			default:
				false
			}
			state.path.append(.accountRecoveryScan(.init(purpose: .addAccounts(factorSourceID: fs.factorSourceID.extract()!, olympia: isOlympiaRecovery))))
			return .none

		case .accountRecoveryScan(.delegate(.dismissed)):
			_ = state.path.popLast()
			return .none

		case .accountRecoveryScan(.delegate(.completed)):
			state.path.append(.recoveryComplete(.init()))
			return .none

		case .recoveryComplete(.delegate(.profileCreatedFromImportedBDFS)):
			return .send(.delegate(.completed))

		default:
			return .none
		}
	}
}
