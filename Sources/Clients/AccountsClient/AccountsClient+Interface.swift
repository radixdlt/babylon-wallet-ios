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

	/// Does NOT save the account in Profile.
	public var migrateOlympiaAccountsToBabylon: MigrateOlympiaAccountsToBabylon

	public init(
		getAccountsOnCurrentNetwork: @escaping GetAccountsOnCurrentNetwork,
		accountsOnCurrentNetwork: @escaping AccountsOnCurrentNetwork,
		getAccountsOnNetwork: @escaping GetAccountsOnNetwork,
		createUnsavedVirtualAccount: @escaping CreateUnsavedVirtualAccount,
		saveVirtualAccount: @escaping SaveVirtualAccount,
		getAccountByAddress: @escaping GetAccountByAddress,
		hasAccountOnNetwork: @escaping HasAccountOnNetwork,
		migrateOlympiaAccountsToBabylon: @escaping MigrateOlympiaAccountsToBabylon
	) {
		self.getAccountsOnCurrentNetwork = getAccountsOnCurrentNetwork
		self.getAccountsOnNetwork = getAccountsOnNetwork
		self.accountsOnCurrentNetwork = accountsOnCurrentNetwork
		self.createUnsavedVirtualAccount = createUnsavedVirtualAccount
		self.saveVirtualAccount = saveVirtualAccount
		self.getAccountByAddress = getAccountByAddress
		self.hasAccountOnNetwork = hasAccountOnNetwork
		self.migrateOlympiaAccountsToBabylon = migrateOlympiaAccountsToBabylon
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

	public typealias MigrateOlympiaAccountsToBabylon = @Sendable (MigrateOlympiaAccountsToBabylonRequest) async throws -> MigratedAccounts
}

// MARK: - MigrateOlympiaAccountsToBabylonRequest
public struct MigrateOlympiaAccountsToBabylonRequest: Sendable, Hashable {
	public let olympiaAccounts: Set<OlympiaAccountToMigrate>
	public let olympiaFactorSource: PrivateHDFactorSource
	public let nextDerivationAccountIndex: Profile.Network.NextDerivationIndices.Index

	public init(
		olympiaAccounts: Set<OlympiaAccountToMigrate>,
		olympiaFactorSource: PrivateHDFactorSource,
		nextDerivationAccountIndex: Profile.Network.NextDerivationIndices.Index
	) {
		self.olympiaAccounts = olympiaAccounts
		self.olympiaFactorSource = olympiaFactorSource
		self.nextDerivationAccountIndex = nextDerivationAccountIndex
	}
}

// MARK: - MigratedAccounts
public struct MigratedAccounts: Sendable, Hashable {
	public let networkID: NetworkID

	public struct MigratedAccount: Sendable, Hashable {
		public let olympia: OlympiaAccountToMigrate
		public let babylon: Profile.Network.Account
		public init(olympia: OlympiaAccountToMigrate, babylon: Profile.Network.Account) {
			self.olympia = olympia
			self.babylon = babylon
		}
	}

	/// Ordered by Olympia `address_index` (as non hardened value)
	public let accounts: NonEmpty<OrderedSet<MigratedAccount>>
	public var babylonAccounts: Profile.Network.Accounts {
		fatalError() // accounts.map(\.babylon)
	}

	public let nextDerivationAccountIndex: Profile.Network.NextDerivationIndices.Index

	public init(
		networkID: NetworkID,
		accounts: NonEmpty<OrderedSet<MigratedAccount>>,
		nextDerivationAccountIndex: Profile.Network.NextDerivationIndices.Index
	) throws {
		guard accounts.allSatisfy({ $0.babylon.networkID == networkID }) else {
			throw NetworkIDDisrepancy()
		}
		self.networkID = networkID
		self.accounts = accounts
		self.nextDerivationAccountIndex = nextDerivationAccountIndex
	}
}

// MARK: - NetworkIDDisrepancy
struct NetworkIDDisrepancy: Swift.Error {}

// MARK: - OlympiaAccountToMigrate
public struct OlympiaAccountToMigrate: Sendable, Hashable, CustomDebugStringConvertible, Identifiable {
	public typealias ID = K1.PublicKey
	public var id: ID { publicKey }
	public let publicKey: K1.PublicKey
	public let path: LegacyOlympiaBIP44LikeDerivationPath
	public let xrd: BigDecimal

	/// Legacy Olympia address
	public let address: LegacyOlympiaAccountAddress

	public let displayName: NonEmptyString?

	/// the non hardened value of the path
	public let addressIndex: HD.Path.Component.Child.Value

	public init(
		publicKey: K1.PublicKey,
		path: LegacyOlympiaBIP44LikeDerivationPath,
		xrd: BigDecimal,
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
		self.xrd = xrd
		self.address = address
		self.displayName = displayName
	}

	public var debugDescription: String {
		"""
		name: \(displayName ?? "")
		xrd: \(xrd.description)
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
