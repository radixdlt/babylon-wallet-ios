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
		case displayAccountDetails(
			Profile.Network.Account,
			needToBackupMnemonicForThisAccount: Bool,
			needToImportMnemonicForThisAccount: Bool
		)

		case backUpMnemonic(controlling: Profile.Network.Account)
		case importMnemonics(account: Profile.Network.Account)
	}

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
			case let .tapped(account, needToBackupMnemonicForThisAccount, needToImportMnemonicForThisAccount):
				return .send(.delegate(.displayAccountDetails(
					account,
					needToBackupMnemonicForThisAccount: needToBackupMnemonicForThisAccount,
					needToImportMnemonicForThisAccount: needToImportMnemonicForThisAccount
				)))

			case let .backUpMnemonic(controllingAccount):
				return .send(.delegate(.backUpMnemonic(controlling: controllingAccount)))
			case let .importMnemonics(account):
				return .send(.delegate(.importMnemonics(account: account)))
			}
		case .account:
			return .none
		}
	}
}
