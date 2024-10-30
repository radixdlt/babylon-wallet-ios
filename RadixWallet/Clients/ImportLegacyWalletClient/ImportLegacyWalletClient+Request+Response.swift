// MARK: - ScannedParsedOlympiaWalletToMigrate
struct ScannedParsedOlympiaWalletToMigrate: Sendable, Hashable {
	let mnemonicWordCount: BIP39WordCount
	let accounts: NonEmpty<OrderedSet<OlympiaAccountToMigrate>>
}

// MARK: - MigrateOlympiaSoftwareAccountsToBabylonRequest
struct MigrateOlympiaSoftwareAccountsToBabylonRequest: Sendable, Hashable {
	let olympiaAccounts: Set<OlympiaAccountToMigrate>
	let olympiaFactorSouceID: FactorSourceIDFromHash
	let olympiaFactorSource: PrivateHierarchicalDeterministicFactorSource?

	init(
		olympiaAccounts: Set<OlympiaAccountToMigrate>,
		olympiaFactorSouceID: FactorSourceIDFromHash,
		olympiaFactorSource: PrivateHierarchicalDeterministicFactorSource?
	) {
		self.olympiaAccounts = olympiaAccounts
		self.olympiaFactorSource = olympiaFactorSource
		self.olympiaFactorSouceID = olympiaFactorSouceID
	}
}

// MARK: - MigrateOlympiaHardwareAccountsToBabylonRequest
struct MigrateOlympiaHardwareAccountsToBabylonRequest: Sendable, Hashable {
	let olympiaAccounts: NonEmpty<Set<OlympiaAccountToMigrate>>
	let ledgerFactorSourceID: FactorSourceIDFromHash

	init(
		olympiaAccounts: NonEmpty<Set<OlympiaAccountToMigrate>>,
		ledgerFactorSourceID: FactorSourceIDFromHash
	) {
		self.olympiaAccounts = olympiaAccounts
		self.ledgerFactorSourceID = ledgerFactorSourceID
	}
}
