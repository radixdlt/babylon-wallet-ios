import Common
import Foundation
import Profile

// MARK: - AccountCompletion.State
public extension AccountCompletion {
	struct State: Equatable {
		public let account: OnNetwork.Account
		public let isFirstAccount: Bool
		public let destination: Destination

		public init(
			account: OnNetwork.Account,
			isFirstAccount: Bool,
			destination: Destination
		) {
			self.account = account
			self.isFirstAccount = isFirstAccount
			self.destination = destination
		}
	}
}

// MARK: - AccountCompletion.State.Origin
public extension AccountCompletion.State {
	enum Destination: String, Sendable {
		case home
		case chooseAccounts

		var displayText: String {
			switch self {
			case .home:
				return L10n.CreateAccount.Completion.Destination.home
			case .chooseAccounts:
				return L10n.CreateAccount.Completion.Destination.chooseAccounts
			}
		}
	}

	var accountAddress: AccountAddress {
		account.address
	}

	var accountName: String {
		account.displayName ?? "Unnamed account"
	}

	var accountIndex: Int {
		account.index
	}
}

#if DEBUG
public extension AccountCompletion.State {
	static let placeholder: Self = .init(
		account: .placeholder0,
		isFirstAccount: true,
		destination: .home
	)
}
#endif
