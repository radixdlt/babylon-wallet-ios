import ComposableArchitecture
import ProfileClient

// MARK: - IncomingConnectionRequestFromDappReview
public struct IncomingConnectionRequestFromDappReview: ReducerProtocol {
	@Dependency(\.profileClient) var profileClient
	public init() {}

	public var body: some ReducerProtocol<State, Action> {
		Scope(state: \State.chooseAccounts!, action: /Action.chooseAccounts) {
			ChooseAccounts()
		}
		Reduce { state, action in
			switch action {
			case .internal(.user(.dismissIncomingConnectionRequest)):
				return .run { send in
					await send(.delegate(.dismiss))
				}

			case .internal(.user(.proceedWithConnectionRequest)):
				return .run { send in
					await send(.internal(.coordinate(.proceedWithConnectionRequest)))
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

			case .internal(.coordinate(.proceedWithConnectionRequest)):
				return .run { send in
					await send(.internal(.system(.loadAccountsResult(TaskResult {
						try profileClient.getAccounts()
					}))))
				}

			case .internal(.coordinate(.dismissIncomingConnectionRequest)):
				return .none

			case .chooseAccounts(.coordinate(.dismissChooseAccounts)):
				state.chooseAccounts = nil
				return .none

			case let .chooseAccounts(.coordinate(.finishedChoosingAccounts(chosenAccounts))):
				state.chooseAccounts = nil
				return .run { send in
					await send(.delegate(.finishedChoosingAccounts(chosenAccounts)))
				}

			case .chooseAccounts:
				return .none
			case .delegate:
				return .none
			}
		}
	}
}
