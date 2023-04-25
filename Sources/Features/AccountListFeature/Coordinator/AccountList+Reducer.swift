import FeaturePrelude

// MARK: - AccountList
public struct AccountList: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var accounts: IdentifiedArrayOf<AccountList.Row.State>

		public init(accounts: IdentifiedArrayOf<AccountList.Row.State>) {
			self.accounts = accounts
		}

		public init(accounts: Profile.Network.Accounts) {
			self.init(
				accounts: .init(uniqueElements: accounts.rawValue.elements.map(AccountList.Row.State.init(account:)))
			)
		}
	}

	public enum ChildAction: Sendable, Equatable {
		case account(id: AccountList.Row.State.ID, action: AccountList.Row.Action)
	}

	public enum DelegateAction: Sendable, Equatable {
		case displayAccountDetails(AccountList.Row.State)
	}

	@Dependency(\.pasteboardClient) var pasteboardClient

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.forEach(\.accounts, action: /Action.child .. ChildAction.account) {
				AccountList.Row()
			}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		// TODO: Should be handled here? maybe in Row child instead
		switch childAction {
		case let .account(id: id, action: action):
			guard let row = state.accounts[id: id] else {
				assertionFailure("Account value should not be nil.")
				return .none
			}
			switch action {
			case .view(.copyAddressButtonTapped):
				let address = row.account.address.address
				return .fireAndForget { pasteboardClient.copyString(address) }
			case .view(.tapped):
				return .send(.delegate(.displayAccountDetails(row)))
			default:
				return .none
			}
		}
	}
}
