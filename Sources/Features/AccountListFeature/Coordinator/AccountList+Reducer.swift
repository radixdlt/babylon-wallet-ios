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
		case displayAccountDetails(Profile.Network.Account)
		case displayAccountSecurity(Profile.Network.Account)
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
		switch childAction {
		case let .account(_, action: .delegate(action)):
			switch action {
			case let .tapped(account):
				return .send(.delegate(.displayAccountDetails(account)))
			case let .securityPrompTaped(account):
				return .send(.delegate(.displayAccountSecurity(account)))
			case let .copyAddressButtonTapped(account):
				let address = account.address.address
				return .fireAndForget { pasteboardClient.copyString(address) }
			}

		default:
			return .none
		}
	}
}
