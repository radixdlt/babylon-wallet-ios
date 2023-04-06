import AccountsClient
import ClientPrelude
import Cryptography
import EngineToolkitClient

// MARK: - ImportLegacyWalletClient
public struct ImportLegacyWalletClient: Sendable {
	public var parseHeaderFromQRCode: ParseHeaderFromQRCode
	public var parseLegacyWalletFromQRCodes: ParseLegacyWalletFromQRCodes

	public var migrateOlympiaSoftwareAccountsToBabylon: MigrateOlympiaSoftwareAccountsToBabylon
	public var migrateOlympiaHardwareAccountsToBabylon: MigrateOlympiaHardwareAccountsToBabylon
}

extension ImportLegacyWalletClient {
	public typealias ParseHeaderFromQRCode = @Sendable (String) throws -> OlympiaExportHeader
	public typealias ParseLegacyWalletFromQRCodes = @Sendable (_ qrCodes: OrderedSet<String>) throws -> ScannedParsedOlympiaWalletToMigrate
	public typealias MigrateOlympiaSoftwareAccountsToBabylon = @Sendable (MigrateOlympiaSoftwareAccountsToBabylonRequest) async throws -> MigratedSoftwareAccounts
	public typealias MigrateOlympiaHardwareAccountsToBabylon = @Sendable (MigrateOlympiaHardwareAccountsToBabylonRequest) async throws -> MigratedHardwareAccounts
}

// MARK: - OlympiaExportHeader
public struct OlympiaExportHeader: Sendable, Hashable {
	/// number of payloads (might be 1)
	public let payloadCount: Int
	/// The word count of the mnemonic to import seperately.
	public let mnemonicWordCount: Int
}

// MARK: - AccountNonChecked
struct AccountNonChecked: Sendable, Hashable {
	let accountType: String
	let pk: String
	let path: String
	let name: String?

	func checked() throws -> OlympiaAccountToMigrate {
		@Dependency(\.engineToolkitClient) var engineToolkitClient
		let publicKeyData = try Data(hex: pk)
		let publicKey = try K1.PublicKey(compressedRepresentation: publicKeyData)

		let bech32Address = try engineToolkitClient.deriveOlympiaAdressFromPublicKey(publicKey)

		guard let nonEmptyString = NonEmptyString(rawValue: bech32Address) else {
			fatalError()
		}
		let address = LegacyOlympiaAccountAddress(address: nonEmptyString)

		guard let accountType = LegacyOlypiaAccountType(rawValue: self.accountType) else {
			fatalError()
		}

		return try .init(
			accountType: accountType,
			publicKey: .init(compressedRepresentation: publicKeyData),
			path: .init(derivationPath: path),
			address: address,
			displayName: name.map { NonEmptyString(rawValue: $0) } ?? nil
		)
	}
}

// MARK: - OlympiaAccountToMigrate
public struct OlympiaAccountToMigrate: Sendable, Hashable, CustomDebugStringConvertible, Identifiable {
	public typealias ID = K1.PublicKey

	public var id: ID { publicKey }

	public let accountType: LegacyOlypiaAccountType

	public let publicKey: K1.PublicKey
	public let path: LegacyOlympiaBIP44LikeDerivationPath

	/// Legacy Olympia address
	public let address: LegacyOlympiaAccountAddress

	public let displayName: NonEmptyString?

	/// the non hardened value of the path
	public let addressIndex: HD.Path.Component.Child.Value

	public init(
		accountType: LegacyOlypiaAccountType,
		publicKey: K1.PublicKey,
		path: LegacyOlympiaBIP44LikeDerivationPath,
		address: LegacyOlympiaAccountAddress,
		displayName: NonEmptyString?
	) throws {
		/// the non hardened value of the path
		guard let addressIndex = path.fullPath.components.last?.asChild?.nonHardenedValue else {
			assertionFailure("bad path")
			throw ExpectedBIP44LikeDerivationPathToAlwaysContainAddressIndex()
		}
		self.addressIndex = addressIndex
		self.publicKey = publicKey
		self.path = path
		self.address = address
		self.displayName = displayName
		self.accountType = accountType
	}

	public var debugDescription: String {
		"""
		accountType: \(accountType)
		name: \(displayName ?? "")
		path: \(path.derivationPath)
		publicKey: \(publicKey.compressedRepresentation.hex)
		"""
	}
}

// MARK: - ImportedOlympiaWalletFailPayloadsEmpty
struct ImportedOlympiaWalletFailPayloadsEmpty: Swift.Error {}

// MARK: - ImportedOlympiaWalletFailInvalidWordCount
struct ImportedOlympiaWalletFailInvalidWordCount: Swift.Error {}

// MARK: - ImportedOlympiaWalletFailedToFindAnyAccounts
struct ImportedOlympiaWalletFailedToFindAnyAccounts: Swift.Error {}

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

// MARK: - MigratedAccount
public struct MigratedAccount: Sendable, Hashable {
	public let olympia: OlympiaAccountToMigrate
	public let babylon: Profile.Network.Account
	public init(olympia: OlympiaAccountToMigrate, babylon: Profile.Network.Account) {
		self.olympia = olympia
		self.babylon = babylon
	}
}

// MARK: - MigratedHardwareAccounts
public struct MigratedHardwareAccounts: Sendable, Hashable {
	public let networkID: NetworkID

	public let accounts: NonEmpty<OrderedSet<MigratedAccount>>
	public var babylonAccounts: Profile.Network.Accounts {
		.init(rawValue: .init(uncheckedUniqueElements: self.accounts.rawValue.elements.map(\.babylon)))!
	}

	public init(
		networkID: NetworkID,
		accounts: NonEmpty<OrderedSet<MigratedAccount>>
	) throws {
		guard accounts.allSatisfy({ $0.babylon.networkID == networkID }) else {
			throw NetworkIDDisrepancy()
		}
		guard accounts.allSatisfy({ $0.olympia.accountType == .hardware }) else {
			throw ExpectedHardwareAccount()
		}
		self.networkID = networkID
		self.accounts = accounts
	}
}

// MARK: - MigratedSoftwareAccounts
public struct MigratedSoftwareAccounts: Sendable, Hashable {
	public let networkID: NetworkID

	public let accounts: NonEmpty<OrderedSet<MigratedAccount>>
	public var babylonAccounts: Profile.Network.Accounts {
		.init(rawValue: .init(uncheckedUniqueElements: self.accounts.rawValue.elements.map(\.babylon)))!
	}

	public let factorSourceToSave: HDOnDeviceFactorSource

	public init(
		networkID: NetworkID,
		accounts: NonEmpty<OrderedSet<MigratedAccount>>,
		factorSourceToSave: HDOnDeviceFactorSource
	) throws {
		guard accounts.allSatisfy({ $0.babylon.networkID == networkID }) else {
			throw NetworkIDDisrepancy()
		}
		guard accounts.allSatisfy({ $0.olympia.accountType == .software }) else {
			throw ExpectedSoftwareAccount()
		}
		self.networkID = networkID
		self.accounts = accounts
		self.factorSourceToSave = factorSourceToSave
	}
}

// MARK: - ExpectedSoftwareAccount
struct ExpectedSoftwareAccount: Error {}

// MARK: - ExpectedHardwareAccount
struct ExpectedHardwareAccount: Error {}

// MARK: - NetworkIDDisrepancy
struct NetworkIDDisrepancy: Swift.Error {}

// MARK: - ExpectedBIP44LikeDerivationPathToAlwaysContainAddressIndex
struct ExpectedBIP44LikeDerivationPathToAlwaysContainAddressIndex: Swift.Error {}

// MARK: - LegacyOlympiaAccountAddress
public struct LegacyOlympiaAccountAddress: Sendable, Hashable {
	/// Bech32, NOT Bech32m, encoded Olympia address
	public let address: NonEmptyString
	public init(address: NonEmptyString) {
		self.address = address
	}
}

// MARK: - LegacyOlypiaAccountType
public enum LegacyOlypiaAccountType: String, Sendable, Hashable, Codable, CustomStringConvertible {
	case software = "S"
	case hardware = "H"
	public var description: String {
		switch self {
		case .software: return "software"
		case .hardware: return "hardware"
		}
	}
}
