// MARK: - ScannedParsedOlympiaWalletToMigrate
struct ScannedParsedOlympiaWalletToMigrate: Hashable {
	let mnemonicWordCount: BIP39WordCount
	let accounts: NonEmpty<OrderedSet<OlympiaAccountToMigrate>>
}

// MARK: - MigrateOlympiaSoftwareAccountsToBabylonRequest
struct MigrateOlympiaSoftwareAccountsToBabylonRequest: Hashable {
	let olympiaAccounts: Set<OlympiaAccountToMigrate>
	let olympiaFactorSouceID: FactorSourceIDFromHash
	let olympiaFactorSource: PrivateHierarchicalDeterministicFactorSource?
}

// MARK: - MigrateOlympiaHardwareAccountsToBabylonRequest
struct MigrateOlympiaHardwareAccountsToBabylonRequest: Hashable {
	let olympiaAccounts: NonEmpty<Set<OlympiaAccountToMigrate>>
	let ledgerFactorSourceID: FactorSourceIDFromHash
}
