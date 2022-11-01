import Foundation
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
	static let placeholderOne: Self = try! Self(account: ProfileClient.mock().getAccounts()[0])
	static let placeholderTwo: Self = try! Self(account: ProfileClient.mock().getAccounts()[1])
}
#endif
