import Foundation

// MARK: - AccountWithInfo
struct AccountWithInfo: Hashable {
	var account: Account

	var isDappDefinitionAccount: Bool = false

	var id: AccountAddress {
		account.address
	}

	var isLegacyAccount: Bool {
		account.isLegacy
	}

	var isLedgerAccount: Bool {
		account.isLedgerControlled
	}
}
