import ClientPrelude
import Cryptography
import Profile

// MARK: - ScannedParsedOlympiaWalletToMigrate
public struct ScannedParsedOlympiaWalletToMigrate: Sendable, Hashable {
	public let mnemonicWordCount: BIP39.WordCount
	public let accounts: NonEmpty<OrderedSet<OlympiaAccountToMigrate>>
}

// MARK: - MigrateOlympiaSoftwareAccountsToBabylonRequest
public struct MigrateOlympiaSoftwareAccountsToBabylonRequest: Sendable, Hashable {
	public let olympiaAccounts: Set<OlympiaAccountToMigrate>
	public let olympiaFactorSouceID: FactorSourceID
	public let olympiaFactorSource: PrivateHDFactorSource?

	public init(
		olympiaAccounts: Set<OlympiaAccountToMigrate>,
		olympiaFactorSouceID: FactorSourceID,
		olympiaFactorSource: PrivateHDFactorSource?
	) {
		self.olympiaAccounts = olympiaAccounts
		self.olympiaFactorSource = olympiaFactorSource
		self.olympiaFactorSouceID = olympiaFactorSouceID
	}
}

// MARK: - MigrateOlympiaHardwareAccountsToBabylonRequest
public struct MigrateOlympiaHardwareAccountsToBabylonRequest: Sendable, Hashable {
	public let olympiaAccounts: Set<OlympiaAccountToMigrate>
	public let ledgerFactorSourceID: FactorSourceID

	public init(
		olympiaAccounts: Set<OlympiaAccountToMigrate>,
		ledgerFactorSourceID: FactorSourceID
	) {
		self.olympiaAccounts = olympiaAccounts
		self.ledgerFactorSourceID = ledgerFactorSourceID
	}
}
