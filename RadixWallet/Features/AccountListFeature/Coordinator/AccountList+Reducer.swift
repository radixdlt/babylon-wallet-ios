import ComposableArchitecture
import SwiftUI

// MARK: - AccountList
public struct AccountList: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var accounts: IdentifiedArrayOf<AccountList.Row.State>

		public init() {
			self.init(accounts: [])
		}

		public init(accounts: IdentifiedArrayOf<Profile.Network.Account>) {
			self.accounts = accounts.map { account in AccountList.Row.State(account: account) }.asIdentifiable()
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

		case deepLinkToDisplayMnemonics
	}

	public init() {}

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.forEach(\.accounts, action: /Action.child .. ChildAction.account) {
				AccountList.Row()
			}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .account(_, action: .delegate(action)):
			switch action {
			case let .tapped(account, needToBackupMnemonicForThisAccount, needToImportMnemonicForThisAccount):
				.send(.delegate(.displayAccountDetails(
					account,
					needToBackupMnemonicForThisAccount: needToBackupMnemonicForThisAccount,
					needToImportMnemonicForThisAccount: needToImportMnemonicForThisAccount
				)))

			case .backUpMnemonic:
				.send(.delegate(.deepLinkToDisplayMnemonics))
			case .importMnemonics:
				.send(.delegate(.deepLinkToDisplayMnemonics))
			}
		case .account:
			.none
		}
	}
}
