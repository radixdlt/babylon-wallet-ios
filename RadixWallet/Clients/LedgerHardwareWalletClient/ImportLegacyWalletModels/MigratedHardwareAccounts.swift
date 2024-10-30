// MARK: - MigratedHardwareAccounts
struct MigratedHardwareAccounts: Sendable, Hashable {
	let networkID: NetworkID
	let ledgerID: LedgerHardwareWalletFactorSource.ID

	let accounts: NonEmpty<OrderedSet<MigratedAccount>>
	var babylonAccounts: Accounts {
		Accounts(accounts.map(\.babylon))
	}

	init(
		networkID: NetworkID,
		ledgerID: LedgerHardwareWalletFactorSource.ID,
		accounts: NonEmpty<OrderedSet<MigratedAccount>>
	) throws {
		guard accounts.allSatisfy({ $0.babylon.networkID == networkID }) else {
			throw NetworkIDDisrepancy()
		}
		guard accounts.allSatisfy({ $0.olympia.accountType == .hardware }) else {
			throw ExpectedHardwareAccount()
		}
		self.ledgerID = ledgerID
		self.networkID = networkID
		self.accounts = accounts
	}
}

extension [MigratedHardwareAccounts] {
	func collectBabylonAccounts() -> IdentifiedArrayOf<Account> {
		var result: IdentifiedArrayOf<Account> = []
		for accounts in self {
			result.append(contentsOf: accounts.babylonAccounts)
		}

		return result
	}
}
