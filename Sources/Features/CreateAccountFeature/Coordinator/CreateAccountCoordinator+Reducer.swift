import ComposableArchitecture
import ErrorQueue
import Foundation
import ProfileClient

public struct CreateAccountCoordinator: Sendable, ReducerProtocol {
	@Dependency(\.profileClient) var profileClient
	@Dependency(\.errorQueue) var errorQueue

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(self.core)
		Scope(state: \.root, action: /Action.self) {
			EmptyReducer()
				.ifCaseLet(/State.Root.createAccount, action: /Action.child .. ChildAction.createAccount) {
					CreateAccount()
				}
				.ifCaseLet(/State.Root.accountCompletion, action: /Action.child .. ChildAction.accountCompletion) {
					AccountCompletion()
				}
		}
	}

	func core(state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case let .child(.createAccount(.delegate(.createdNewAccount(account)))):
			state.root = .accountCompletion(
				.init(
					account: account,
					isFirstAccount: false,
					destination: state.completionDestination
				)
			)
			return .none
		case .internal(.system(.injectProfileIntoProfileClientResult(.success))):
			return .run { send in
				await send(.internal(.system(.loadAccountResult(
					TaskResult {
						try await profileClient.getAccounts().first
					}
				))))
			}
		case let .internal(.system(.injectProfileIntoProfileClientResult(.failure(error)))):
			errorQueue.schedule(error)
			return .none
		case let .internal(.system(.loadAccountResult(.success(account)))):
			state.root = .accountCompletion(
				.init(
					account: account,
					isFirstAccount: true,
					destination: state.completionDestination
				)
			)
			return .none
		case let .child(.createAccount(.delegate(.createdNewProfile(profile)))):
			return .run { send in
				await send(.internal(.system(.injectProfileIntoProfileClientResult(
					TaskResult {
						try await profileClient.injectProfile(profile)
						return profile
					}
				))))
			}
		case .child(.createAccount(.delegate(.dismissCreateAccount))):
			return .run { send in
				await send(.delegate(.dismissed))
			}
		case .child(.accountCompletion(.delegate(.completed))):
			return .run { send in
				await send(.delegate(.completed))
			}
		default:
			return .none
		}
	}
}
