import ComposableArchitecture

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
			case .coordinate(.proceedWithConnectionRequest):
				let accounts = try! profileClient.getAccounts()
				state.chooseAccounts = .init(
					incomingConnectionRequestFromDapp: state.incomingConnectionRequestFromDapp,
					accounts: .init(uniqueElements: accounts.rawValue.elements.map {
						ChooseAccounts.Row.State(account: $0)
					})
				)
				return .none

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
