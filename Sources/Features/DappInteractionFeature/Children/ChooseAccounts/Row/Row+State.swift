import FeaturePrelude

// MARK: - ChooseAccounts.Row.State
extension ChooseAccounts.Row {
	struct State: Hashable {
		let account: OnNetwork.Account
		var isSelected: Bool

		init(
			account: OnNetwork.Account,
			isSelected: Bool = false
		) {
			self.account = account
			self.isSelected = isSelected
		}
	}
}

// MARK: - ChooseAccounts.Row.State + Identifiable
extension ChooseAccounts.Row.State: Identifiable {
	typealias ID = AccountAddress
	var address: AccountAddress { account.address }
	var id: ID { address }
}

#if DEBUG
extension ChooseAccounts.Row.State {
	static let previewValueOne = Self(account: .previewValue0)
	static let previewValueTwo = Self(account: .previewValue1)
}
#endif
