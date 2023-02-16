import FeaturePrelude

// MARK: - AccountList.State
extension AccountList {
	// MARK: State
	public struct State: Sendable, Hashable {
		public var accounts: IdentifiedArrayOf<AccountList.Row.State>
		public var alert: AlertState<Action.ViewAction>?

		public init(
			accounts: IdentifiedArrayOf<AccountList.Row.State>,
			alert: AlertState<Action.ViewAction>? = nil
		) {
			self.accounts = accounts
			self.alert = alert
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
extension Array where Element == AccountList.Row.State {
	public static let previewValue: Self = []
}

extension IdentifiedArray where Element == AccountList.Row.State, ID == AccountList.Row.State.ID {
	public static let previewValue: Self = .init(uniqueElements: Array<AccountList.Row.State>.previewValue)
}

#endif
