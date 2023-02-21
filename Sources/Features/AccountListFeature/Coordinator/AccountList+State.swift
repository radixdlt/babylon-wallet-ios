import FeaturePrelude

// MARK: - AccountList.State
extension AccountList {
	// MARK: State
	public struct State: Sendable, Hashable {
		public var accounts: IdentifiedArrayOf<AccountList.Row.State>

		public init(
			accounts: IdentifiedArrayOf<AccountList.Row.State>
		) {
			self.accounts = accounts
		}
	}
}

// MARK: - Convenience
extension AccountList.State {
	public init(accounts: NonEmpty<IdentifiedArrayOf<OnNetwork.Account>>) {
		self.init(
			accounts: .init(uniqueElements: accounts.rawValue.elements.map(AccountList.Row.State.init(account:)))
		)
	}
}

#if DEBUG
extension AccountList.State {
	static let previewValue: Self = .init(
		accounts: .init(uniqueElements: [.previewValue]))
}

extension Array where Element == AccountList.Row.State {
	public static let previewValue: Self = []
}

extension IdentifiedArray where Element == AccountList.Row.State, ID == AccountList.Row.State.ID {
	public static let previewValue: Self = .init(uniqueElements: Array<AccountList.Row.State>.previewValue)
}

#endif
