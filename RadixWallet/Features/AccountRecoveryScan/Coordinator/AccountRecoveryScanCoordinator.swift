// MARK: - AccountRecoveryScanCoordinator

public struct AccountRecoveryScanCoordinator: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		/// ID of factor to derive public keys with (addresses)
		public let factorSourceID: FactorSourceID

		/// Create new Profile or add accounts
		public let purpose: Purpose

		public var root: AccountRecoveryScanStart.State
		public var path: StackState<Path.State> = .init()

		/// Create new Profile or add accounts
		public enum Purpose: Sendable, Hashable {
			case createProfile
			case addAccounts
		}

		public init(factorSourceID: FactorSourceID, purpose: Purpose) {
			self.factorSourceID = factorSourceID
			self.purpose = purpose
			self.root = .init()
		}
	}

	public struct Path: Sendable, Hashable, Reducer {
		public enum State: Sendable, Hashable {
			case end(AccountRecoveryScanEnd.State)
		}

		public enum Action: Sendable, Equatable {
			case end(AccountRecoveryScanEnd.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(state: /State.end, action: /Action.end) {
				AccountRecoveryScanEnd()
			}
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case closeTapped
	}

	public enum ChildAction: Sendable, Equatable {
		case root(AccountRecoveryScanStart.Action)
		case path(StackActionOf<Path>)
	}

	public enum InternalAction: Sendable, Equatable {
		case createProfileResult(TaskResult<EqVoid>)
		case addAccountsToExistingProfileResult(TaskResult<EqVoid>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case completed
		case dismissed
	}

	@Dependency(\.onboardingClient) var onboardingClient
	@Dependency(\.accountsClient) var accountsClient
	@Dependency(\.dismiss) var dismiss
	public init() {}

	public var body: some ReducerOf<Self> {
		Scope(state: \.root, action: /Action.child .. ChildAction.root) {
			AccountRecoveryScanStart()
		}

		Reduce(core)
			.forEach(\.path, action: /Action.child .. ChildAction.path) {
				Path()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .closeTapped:
			.run { send in
				await dismiss()
				await send(.delegate(.dismissed))
			}
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .addAccountsToExistingProfileResult(.success):
			.send(.delegate(.completed))
		case let .addAccountsToExistingProfileResult(.failure(error)):
			fatalError("todo error handling")
		case let .createProfileResult(.success):
			.send(.delegate(.completed))
		case let .createProfileResult(.failure(error)):
			fatalError("todo error handling")
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case .root(.delegate(.continue)):
			state.path.append(.end(.init()))
			return .none

		case let .path(.element(_, action: .end(.delegate(.finishedAccountRecoveryScan(active, inactive))))):
			switch state.purpose {
			case .createProfile:
				guard let bdfsID = state.factorSourceID.extract(FactorSource.ID.FromHash.self) else {
					fatalError("TODO error handling")
				}
				let accounts = Array(active).asIdentifiable()
				let recoveredAccountAndBDFS = AccountsRecoveredFromScanningUsingMnemonic(
					accounts: accounts,
					factorSourceIDOfBDFSAlreadySavedIntoKeychain: bdfsID
				)
				return .run { send in
					let result = await TaskResult<EqVoid> {
						try await onboardingClient.finishOnboardingWithRecoveredAccountAndBDFS(recoveredAccountAndBDFS)
					}
					await send(.internal(.createProfileResult(result)))
				}
			case .addAccounts:
				return .run { send in
					let result = await TaskResult<EqVoid> {
						try await accountsClient.saveVirtualAccounts(Array(active))
					}
					await send(.internal(.addAccountsToExistingProfileResult(result)))
				}
			}

		default: return .none
		}
	}
}
