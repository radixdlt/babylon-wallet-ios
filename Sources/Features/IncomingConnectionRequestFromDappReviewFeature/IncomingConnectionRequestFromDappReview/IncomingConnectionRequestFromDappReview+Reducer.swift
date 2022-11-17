import ComposableArchitecture
import ProfileClient

// MARK: - IncomingConnectionRequestFromDappReview
public struct IncomingConnectionRequestFromDappReview: ReducerProtocol {
	@Dependency(\.profileClient) var profileClient
	public init() {}

	public var body: some ReducerProtocol<State, Action> {
		Scope(state: \State.chooseAccounts!, action: /Action.child .. Action.ChildAction.chooseAccounts) {
			ChooseAccounts()
		}

		Reduce(self.core)
	}

	func core(state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.view(.dismissButtonTapped)):
			return .run { [dismissedRequest = state.request] send in
				await send(.delegate(.dismiss(dismissedRequest)))
			}

		case .internal(.view(.continueButtonTapped)):
			return .run { send in
				await send(.internal(.system(.loadAccountsResult(TaskResult {
					try profileClient.getAccounts()
				}))))
			}

		case let .internal(.system(.loadAccountsResult(.success(accounts)))):

			state.chooseAccounts = .init(
				request: state.request,
				accounts: .init(uniqueElements: accounts.map {
					ChooseAccounts.Row.State(account: $0)
				})
			)
			return .none

		case let .internal(.system(.loadAccountsResult(.failure(error)))):
			print("⚠️ failed to load accounts, error: \(String(describing: error))")
			return .none

		case .child(.chooseAccounts(.delegate(.dismissChooseAccounts))):
			state.chooseAccounts = nil
			return .none

		case let .child(.chooseAccounts(.delegate(.finishedChoosingAccounts(chosenAccounts)))):
			state.chooseAccounts = nil
			return .run { [request = state.request] send in
				await send(.delegate(
					.finishedChoosingAccounts(chosenAccounts, request: request)
				))
			}

		case .child, .delegate:
			return .none
		}
	}
}
