import IdentifiedCollections
import Sargon

// MARK: - AccountsClient
public struct AccountsClient: Sendable {
	public var getCurrentNetworkID: GetCurrentNetworkID
	public var nextAppearanceID: NextAppearanceID

	/// Accounts on current network (active gateway)
	public var getAccountsOnCurrentNetwork: GetAccountsOnCurrentNetwork

	public var getHiddenAccountsOnCurrentNetwork: GetHiddenAccountsOnCurrentNetwork

	/// Async sequence of Accounts valuues on current network (active gateway), emits new
	/// value of Accounts when you switch network (if new active gateway is on a new network).
	public var accountsOnCurrentNetwork: AccountsOnCurrentNetwork

	/// Allows subscribing to any account updates
	public var accountUpdates: AccountUpdates

	public var newVirtualAccount: NewVirtualAccount

	/// Saves virtual accounts into the profile.
	public var saveVirtualAccounts: SaveVirtualAccounts

	/// Try to perform lookup of account by account address.
	public var getAccountByAddress: GetAccountByAddress

	public var getAccountsOnNetwork: GetAccountsOnNetwork

	public var hasAccountOnNetwork: HasAccountOnNetwork

	public var updateAccount: UpdateAccount

	#if DEBUG
	public var debugOnlyDeleteAccount: DebugOnlyDeleteAccount
	#endif

	#if DEBUG
	public init(
		getCurrentNetworkID: @escaping GetCurrentNetworkID,
		nextAppearanceID: @escaping NextAppearanceID,
		getAccountsOnCurrentNetwork: @escaping GetAccountsOnCurrentNetwork,
		getHiddenAccountsOnCurrentNetwork: @escaping GetHiddenAccountsOnCurrentNetwork,
		accountsOnCurrentNetwork: @escaping AccountsOnCurrentNetwork,
		accountUpdates: @escaping AccountUpdates,
		getAccountsOnNetwork: @escaping GetAccountsOnNetwork,
		newVirtualAccount: @escaping NewVirtualAccount,
		saveVirtualAccounts: @escaping SaveVirtualAccounts,
		getAccountByAddress: @escaping GetAccountByAddress,
		hasAccountOnNetwork: @escaping HasAccountOnNetwork,
		updateAccount: @escaping UpdateAccount,
		debugOnlyDeleteAccount: @escaping DebugOnlyDeleteAccount
	) {
		self.getCurrentNetworkID = getCurrentNetworkID
		self.nextAppearanceID = nextAppearanceID
		self.getAccountsOnCurrentNetwork = getAccountsOnCurrentNetwork
		self.getHiddenAccountsOnCurrentNetwork = getHiddenAccountsOnCurrentNetwork
		self.getAccountsOnNetwork = getAccountsOnNetwork
		self.accountsOnCurrentNetwork = accountsOnCurrentNetwork
		self.accountUpdates = accountUpdates
		self.newVirtualAccount = newVirtualAccount
		self.saveVirtualAccounts = saveVirtualAccounts
		self.getAccountByAddress = getAccountByAddress
		self.hasAccountOnNetwork = hasAccountOnNetwork
		self.updateAccount = updateAccount
		self.debugOnlyDeleteAccount = debugOnlyDeleteAccount
	}
	#else
	public init(
		getCurrentNetworkID: @escaping GetCurrentNetworkID,
		nextAppearanceID: @escaping NextAppearanceID,
		getAccountsOnCurrentNetwork: @escaping GetAccountsOnCurrentNetwork,
		getHiddenAccountsOnCurrentNetwork: @escaping GetHiddenAccountsOnCurrentNetwork,
		accountsOnCurrentNetwork: @escaping AccountsOnCurrentNetwork,
		accountUpdates: @escaping AccountUpdates,
		getAccountsOnNetwork: @escaping GetAccountsOnNetwork,
		newVirtualAccount: @escaping NewVirtualAccount,
		saveVirtualAccounts: @escaping SaveVirtualAccounts,
		getAccountByAddress: @escaping GetAccountByAddress,
		hasAccountOnNetwork: @escaping HasAccountOnNetwork,
		updateAccount: @escaping UpdateAccount
	) {
		self.getCurrentNetworkID = getCurrentNetworkID
		self.nextAppearanceID = nextAppearanceID
		self.getAccountsOnCurrentNetwork = getAccountsOnCurrentNetwork
		self.getHiddenAccountsOnCurrentNetwork = getHiddenAccountsOnCurrentNetwork
		self.getAccountsOnNetwork = getAccountsOnNetwork
		self.accountsOnCurrentNetwork = accountsOnCurrentNetwork
		self.accountUpdates = accountUpdates
		self.newVirtualAccount = newVirtualAccount
		self.saveVirtualAccounts = saveVirtualAccounts
		self.getAccountByAddress = getAccountByAddress
		self.hasAccountOnNetwork = hasAccountOnNetwork
		self.updateAccount = updateAccount
	}
	#endif
}

extension AccountsClient {
	public typealias GetCurrentNetworkID = @Sendable () async -> NetworkID

	public typealias NextAppearanceID = @Sendable (NetworkID?, _ offset: Int?) async -> AppearanceID

	public typealias GetAccountsOnCurrentNetwork = @Sendable () async throws -> Accounts
	public typealias GetHiddenAccountsOnCurrentNetwork = @Sendable () async throws -> Accounts
	public typealias GetAccountsOnNetwork = @Sendable (NetworkID) async throws -> Accounts

	public typealias AccountsOnCurrentNetwork = @Sendable () async -> AnyAsyncSequence<Accounts>
	public typealias AccountUpdates = @Sendable (AccountAddress) async -> AnyAsyncSequence<Account>

	public typealias NewVirtualAccount = @Sendable (NewAccountRequest) async throws -> Account
	public typealias SaveVirtualAccounts = @Sendable (Accounts) async throws -> Void

	public typealias GetAccountByAddress = @Sendable (AccountAddress) async throws -> Account

	public typealias HasAccountOnNetwork = @Sendable (NetworkID) async throws -> Bool

	public typealias UpdateAccount = @Sendable (Account) async throws -> Void
	#if DEBUG
	public typealias DebugOnlyDeleteAccount = @Sendable (Account) async throws -> Void
	#endif
}

// MARK: - NewAccountRequest
public struct NewAccountRequest: Sendable, Hashable {
	public let name: NonEmptyString
	public let factorInstance: HierarchicalDeterministicFactorInstance
	public let networkID: NetworkID
	public init(name: NonEmptyString, factorInstance: HierarchicalDeterministicFactorInstance, networkID: NetworkID) {
		self.name = name
		self.factorInstance = factorInstance
		self.networkID = networkID
	}
}

extension AccountsClient {
	/// Saves a virtual account into the profile.
	public func saveVirtualAccount(_ account: Account) async throws {
		try await saveVirtualAccounts([account])
	}
}
