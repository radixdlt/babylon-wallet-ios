import ClientPrelude
import Cryptography
import Profile

// MARK: - OlympiaExportHeader
public struct OlympiaExportHeader: Sendable, Hashable {
	/// number of payloads (might be 1)
	public let payloadCount: Int
	/// The word count of the mnemonic to import seperately.
	public let mnemonicWordCount: Int
}

// MARK: - ScannedParsedOlympiaWalletToMigrate
public struct ScannedParsedOlympiaWalletToMigrate: Sendable, Hashable {
	public let mnemonicWordCount: BIP39.WordCount
	public let accounts: NonEmpty<OrderedSet<OlympiaAccountToMigrate>>
}

// MARK: - MigrateOlympiaSoftwareAccountsToBabylonRequest
public struct MigrateOlympiaSoftwareAccountsToBabylonRequest: Sendable, Hashable {
	public let olympiaAccounts: Set<OlympiaAccountToMigrate>
	public let olympiaFactorSource: PrivateHDFactorSource

	public init(
		olympiaAccounts: Set<OlympiaAccountToMigrate>,
		olympiaFactorSource: PrivateHDFactorSource
	) {
		self.olympiaAccounts = olympiaAccounts
		self.olympiaFactorSource = olympiaFactorSource
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
