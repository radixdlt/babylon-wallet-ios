import FeaturePrelude
import Foundation

public struct CreateAccountCoordinator: Sendable, ReducerProtocol {
	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Scope(state: \.root, action: /Action.self) {
			EmptyReducer()
				.ifCaseLet(/State.Root.createAccount, action: /Action.child .. Action.ChildAction.createAccount) {
					CreateAccount()
				}
				.ifCaseLet(/State.Root.accountCompletion, action: /Action.child .. Action.ChildAction.accountCompletion) {
					AccountCompletion()
				}
		}
		Reduce(self.core)
	}

	private func core(state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case let .child(.createAccount(.delegate(.createdNewAccount(account, isFirstAccount)))):
			state.root = .accountCompletion(
				.init(
					account: account,
					isFirstAccount: isFirstAccount,
					destination: state.completionDestination
				)
			)
			return .none

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
