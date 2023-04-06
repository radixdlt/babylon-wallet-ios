import ClientPrelude
import Cryptography
import Profile

// MARK: - AccountsClient
public struct AccountsClient: Sendable {
	/// Accounts on current network (active gateway)
	public var getAccountsOnCurrentNetwork: GetAccountsOnCurrentNetwork

	/// Async sequence of Accounts valuues on current network (active gateway), emits new
	/// value of Accounts when you switch network (if new active gateway is on a new network).
	public var accountsOnCurrentNetwork: AccountsOnCurrentNetwork

	/// Creates a new virtual account without saving it into the profile
	public var createUnsavedVirtualAccount: CreateUnsavedVirtualAccount

	/// Saves a virtual account into the profile.
	public var saveVirtualAccount: SaveVirtualAccount

	/// Try to perform lookup of account by account address.
	public var getAccountByAddress: GetAccountByAddress

	public var getAccountsOnNetwork: GetAccountsOnNetwork

	public var hasAccountOnNetwork: HasAccountOnNetwork

	public var migrateOlympiaSoftwareAccountsToBabylon: MigrateOlympiaSoftwareAccountsToBabylon
	public var migrateOlympiaHardwareAccountsToBabylon: MigrateOlympiaHardwareAccountsToBabylon

	public init(
		getAccountsOnCurrentNetwork: @escaping GetAccountsOnCurrentNetwork,
		accountsOnCurrentNetwork: @escaping AccountsOnCurrentNetwork,
		getAccountsOnNetwork: @escaping GetAccountsOnNetwork,
		createUnsavedVirtualAccount: @escaping CreateUnsavedVirtualAccount,
		saveVirtualAccount: @escaping SaveVirtualAccount,
		getAccountByAddress: @escaping GetAccountByAddress,
		hasAccountOnNetwork: @escaping HasAccountOnNetwork,
		migrateOlympiaSoftwareAccountsToBabylon: @escaping MigrateOlympiaSoftwareAccountsToBabylon,
		migrateOlympiaHardwareAccountsToBabylon: @escaping MigrateOlympiaHardwareAccountsToBabylon
	) {
		self.getAccountsOnCurrentNetwork = getAccountsOnCurrentNetwork
		self.getAccountsOnNetwork = getAccountsOnNetwork
		self.accountsOnCurrentNetwork = accountsOnCurrentNetwork
		self.createUnsavedVirtualAccount = createUnsavedVirtualAccount
		self.saveVirtualAccount = saveVirtualAccount
		self.getAccountByAddress = getAccountByAddress
		self.hasAccountOnNetwork = hasAccountOnNetwork
		self.migrateOlympiaSoftwareAccountsToBabylon = migrateOlympiaSoftwareAccountsToBabylon
		self.migrateOlympiaHardwareAccountsToBabylon = migrateOlympiaHardwareAccountsToBabylon
	}
}

extension AccountsClient {
	public typealias GetAccountsOnCurrentNetwork = @Sendable () async throws -> Profile.Network.Accounts
	public typealias GetAccountsOnNetwork = @Sendable (NetworkID) async throws -> Profile.Network.Accounts

	public typealias AccountsOnCurrentNetwork = @Sendable () async -> AnyAsyncSequence<Profile.Network.Accounts>

	public typealias CreateUnsavedVirtualAccount = @Sendable (CreateVirtualEntityRequest) async throws -> Profile.Network.Account
	public typealias SaveVirtualAccount = @Sendable (Profile.Network.Account) async throws -> Void

	public typealias GetAccountByAddress = @Sendable (AccountAddress) async throws -> Profile.Network.Account

	public typealias HasAccountOnNetwork = @Sendable (NetworkID) async throws -> Bool

	public typealias MigrateOlympiaSoftwareAccountsToBabylon = @Sendable (MigrateOlympiaSoftwareAccountsToBabylonRequest) async throws -> MigratedSoftwareAccounts
	public typealias MigrateOlympiaHardwareAccountsToBabylon = @Sendable (MigrateOlympiaHardwareAccountsToBabylonRequest) async throws -> MigratedHardwareAccounts
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
