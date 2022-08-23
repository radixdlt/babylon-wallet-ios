import ComposableArchitecture

public extension Home.AccountList {
	// MARK: Reducer
	typealias Reducer = ComposableArchitecture.Reducer<State, Action, Environment>
	static let reducer = Reducer.combine(
		Home.AccountRow.reducer.forEach(
			state: \.accounts,
			action: /Home.AccountList.Action.account(id:action:),
			environment: { _ in Home.AccountRow.Environment() }
		),

		Reducer { state, action, environment in
			switch action {
			case .internal(.system(.viewDidAppear)):
				return .run { send in
					let accounts = try await environment.wallet.loadAccounts()
					await send(.internal(.system(.loadAccountResult(.success(accounts)))))
				} catch: { error, send in
					await send(.internal(.system(.loadAccountResult(.failure(error)))))
				}
			case .coordinate:
				return .none
			case let .account(id: id, action: action):
				guard let account = state.accounts.first(where: { $0.id == id }) else {
					preconditionFailure("Account value should not be nil.")
					return .none
				}
				switch action {
				case .internal(.user(.copyAddress)):
					return .run { send in
						await send(.coordinate(.copyAddress(account)))
					}
				case .internal(.user(.didSelect)):
					return .run { send in
						await send(.coordinate(.displayAccountDetails(account)))
					}
				}
			case let .internal(.system(.loadAccountResult(.success(accounts)))):
				state.accounts = .init(uniqueElements: accounts.map(Home.AccountRow.State.init(profileAccount:)))
				return .none
			case let .internal(.system(.loadAccountResult(.failure(error)))):
				state.alert = .init(title: .init("Failed to load accounts: \(error.localizedDescription)"))
				return .none
			case .internal(.user(.alertDismissed)):
				state.alert = nil
				return .none
			}
		}
	)
}
