import FeaturePrelude
import Profile

// MARK: - AccountCompletion.State
public extension AccountCompletion {
	struct State: Sendable, Equatable {
		public let account: OnNetwork.Account
		public let isFirstAccount: Bool
		public let destination: CreateAccountCompletionDestination

		public init(
			account: OnNetwork.Account,
			isFirstAccount: Bool,
			destination: CreateAccountCompletionDestination
		) {
			self.account = account
			self.isFirstAccount = isFirstAccount
			self.destination = destination
		}
	}
}

// MARK: - AccountCompletion.State.Origin
public extension AccountCompletion.State {
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
	static let previewValue: Self = .init(
		account: .previewValue0,
		isFirstAccount: true,
		destination: .home
	)
}
#endif
