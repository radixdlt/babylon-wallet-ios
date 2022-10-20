import ComposableArchitecture

// MARK: - ChooseAccounts
public struct ChooseAccounts: ReducerProtocol {
	public init() {}
}

public extension ChooseAccounts {
    /*
	func reduce(into _: inout State, action _: Action) -> ComposableArchitecture.Effect<Action, Never> {
		.none
	}
    */
    
    var body: some ReducerProtocol<State, Action> {
      Reduce { state, action in
          return .none
      }
      .forEach(\.accounts, action: /Action.account(id:action:)) {
          ChooseAccounts.Row()
      }
    }

}

/*
AccountList.Row.reducer.forEach(
    state: \.accounts,
    action: /AccountList.Action.account(id:action:),
    environment: { _ in AccountList.Row.Environment() }
),
*/
