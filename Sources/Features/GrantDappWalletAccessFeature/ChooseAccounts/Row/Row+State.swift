import FeaturePrelude
import Profile

// MARK: - ChooseAccounts.Row.State
public extension ChooseAccounts.Row {
	struct State: Equatable {
		public let account: OnNetwork.Account
		public var isSelected: Bool = false

		public init(
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
	public typealias ID = AccountAddress
	public var address: AccountAddress { account.address }
	public var id: ID { address }
}

#if DEBUG
import ProfileClient
public extension ChooseAccounts.Row.State {
	static let previewValueOne = Self(account: .previewValue0)
	static let previewValueTwo = Self(account: .previewValue1)
}
#endif
