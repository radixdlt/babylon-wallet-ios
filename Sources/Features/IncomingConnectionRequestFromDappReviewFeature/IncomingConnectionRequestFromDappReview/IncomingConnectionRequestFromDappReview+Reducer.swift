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
					await send(.coordinate(.dismissIncomingConnectionRequest))
				}

			case .internal(.user(.proceedWithConnectionRequest)):
				return .run { send in
					await send(.coordinate(.proceedWithConnectionRequest))
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

			case .coordinate(.proceedWithConnectionRequest):
				return .run { send in
					await send(.internal(.system(.loadAccountsResult(TaskResult {
						try profileClient.getAccounts()
					}))))
				}

			case .coordinate(.dismissIncomingConnectionRequest):
				return .none

			case .chooseAccounts(.coordinate(.dismissChooseAccounts)):
				state.chooseAccounts = nil
				return .none

			case .chooseAccounts:
				return .none
			}
		}
	}
}
