import Foundation

// MARK: - AccountWithInfo
struct AccountWithInfo: Sendable, Hashable {
	var account: Account

	var isDappDefinitionAccount: Bool = false

	init(account: Account) {
		self.account = account
	}

	var id: AccountAddress { account.address }
	var isLegacyAccount: Bool { account.isLegacy }
	var isLedgerAccount: Bool { account.isLedgerControlled }
}
