import Cryptography
import DerivePublicKeysFeature
import FactorSourcesClient
import FeaturePrelude

// MARK: - CreateAccountCoordinator
public struct CreateAccountCoordinator: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		var root: Destinations.State?
		var path: StackState<Destinations.State> = .init()

		public let config: CreateAccountConfig

		public init(
			root: Destinations.State? = nil,
			config: CreateAccountConfig
		) {
			self.config = config
			if let root {
				self.root = root
			} else {
				self.root = .step1_nameAccount(.init(config: config))
			}
		}

		var shouldDisplayNavBar: Bool {
			guard config.canBeDismissed else {
				return false
			}
			if let last = path.last {
				if case .step3_completion = last {
					return false
				} else if case let .step2_creationOfAccount(creationOfAccount) = last {
					return creationOfAccount.isCreatingLedgerAccount
				} else {
					return true
				}
			}
			return true
		}
	}

	public struct Destinations: Sendable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case step_first
			case step_last

			case step1_nameAccount(NameAccount.State)
			case step2_creationOfAccount(CreationOfAccount.State)
			case step3_completion(NewAccountCompletion.State)
		}

		public enum Action: Sendable, Equatable {
			case step1_nameAccount(NameAccount.Action)
			case step2_creationOfAccount(CreationOfAccount.Action)
			case step3_completion(NewAccountCompletion.Action)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.step1_nameAccount, action: /Action.step1_nameAccount) {
				NameAccount()
			}
			Scope(state: /State.step2_creationOfAccount, action: /Action.step2_creationOfAccount) {
				CreationOfAccount()
			}
			Scope(state: /State.step3_completion, action: /Action.step3_completion) {
				NewAccountCompletion()
			}
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case closeButtonTapped
	}

	public enum ChildAction: Sendable, Equatable {
		case root(Destinations.Action)
		case path(StackActionOf<Destinations>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case dismissed
		case completed
	}

	@Dependency(\.factorSourcesClient) var factorSourcesClient
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.isPresented) var isPresented
	@Dependency(\.dismiss) var dismiss

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(\.root, action: /Action.child .. ChildAction.root) {
				Destinations()
			}
			.forEach(\.path, action: /Action.child .. ChildAction.path) {
				Destinations()
			}
	}
}

extension CreateAccountCoordinator {
	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .closeButtonTapped:
			assert(state.config.canBeDismissed)
			return .run { send in
				await send(.delegate(.dismissed))
				if isPresented {
					await dismiss()
				}
			}
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .root(.step1_nameAccount(.delegate(.proceed(accountName, useLedgerAsFactorSource)))):
			state.path.append(.step2_creationOfAccount(.init(
				name: accountName,
				networkID: state.config.specificNetworkID,
				isCreatingLedgerAccount: useLedgerAsFactorSource
			)))
			return .none

		case let .path(.element(_, action: .step2_creationOfAccount(.delegate(.createdAccount(newAccount))))):
			state.path.append(.step3_completion(.init(
				account: newAccount,
				config: state.config
			)))
			return .none

		case .path(.element(_, action: .step2_creationOfAccount(.delegate(.createAccountFailed)))):
			state.path.removeLast()
			return .none

		case .path(.element(_, action: .step3_completion(.delegate(.completed)))):
			return .run { send in
				await send(.delegate(.completed))
				if isPresented {
					await dismiss()
				}
			}

		default:
			return .none
		}
	}
}
