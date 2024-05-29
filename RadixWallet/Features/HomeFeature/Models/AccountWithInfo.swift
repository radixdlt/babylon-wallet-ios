import Foundation

// MARK: - AccountWithInfo
public struct AccountWithInfo: Sendable, Hashable {
	public var account: Account

	public var isDappDefinitionAccount: Bool = false

	init(account: Account) {
		self.account = account
	}

	public var id: AccountAddress { account.address }
	public var isLegacyAccount: Bool { account.isLegacy }
	public var isLedgerAccount: Bool { account.isLedgerControlled }
}
