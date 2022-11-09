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
		Reduce { state, action in
			switch action {
			case .internal(.view(.dismissButtonTapped)):
				return .run { send in
					await send(.delegate(.dismiss))
				}

			case .internal(.view(.continueButtonTapped)):
				return .run { send in
					await send(.internal(.system(.loadAccountsResult(TaskResult {
						try profileClient.getAccounts()
					}))))
				}

			case let .internal(.system(.loadAccountsResult(.success(accounts)))):
				state.chooseAccounts = .init(
					incomingConnectionRequestFromDapp: state.incomingConnectionRequestFromDapp,
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
				return .run { [incomingMessageFromBrowser = state.incomingMessageFromBrowser] send in
					await send(.delegate(
						.finishedChoosingAccounts(chosenAccounts, incomingMessageFromBrowser: incomingMessageFromBrowser)
					))
				}

			case .child, .delegate:
				return .none
			}
		}
	}
}
