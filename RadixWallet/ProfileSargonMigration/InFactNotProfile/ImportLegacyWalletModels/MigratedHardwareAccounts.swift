// MARK: - MigratedHardwareAccounts
public struct MigratedHardwareAccounts: Sendable, Hashable {
	public let networkID: NetworkID
	public let ledgerID: LedgerHardwareWalletFactorSource.ID

	public let accounts: NonEmpty<OrderedSet<MigratedAccount>>
	public var babylonAccounts: IdentifiedArrayOf<Sargon.Account> {
		accounts.elements.map(\.babylon).asIdentified()
	}

	public init(
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
	public func collectBabylonAccounts() -> IdentifiedArrayOf<Sargon.Account> {
		var result: IdentifiedArrayOf<Sargon.Account> = []
		for accounts in self {
			result.append(contentsOf: accounts.babylonAccounts)
		}

		return result
	}
}
