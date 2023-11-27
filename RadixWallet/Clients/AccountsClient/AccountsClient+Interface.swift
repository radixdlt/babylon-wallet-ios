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
}

extension AccountsClient {
	public typealias Accounts = IdentifiedArrayOf<Profile.Network.Account>

	public typealias GetCurrentNetworkID = @Sendable () async -> NetworkID

	public typealias NextAppearanceID = @Sendable (NetworkID?, _ offset: Int?) async -> Profile.Network.Account.AppearanceID

	public typealias GetAccountsOnCurrentNetwork = @Sendable () async throws -> Accounts
	public typealias GetHiddenAccountsOnCurrentNetwork = @Sendable () async throws -> Accounts
	public typealias GetAccountsOnNetwork = @Sendable (NetworkID) async throws -> Accounts

	public typealias AccountsOnCurrentNetwork = @Sendable () async -> AnyAsyncSequence<Accounts>
	public typealias AccountUpdates = @Sendable (AccountAddress) async -> AnyAsyncSequence<Profile.Network.Account>

	public typealias NewVirtualAccount = @Sendable (NewAccountRequest) async throws -> Profile.Network.Account
	public typealias SaveVirtualAccounts = @Sendable ([Profile.Network.Account]) async throws -> Void

	public typealias GetAccountByAddress = @Sendable (AccountAddress) async throws -> Profile.Network.Account

	public typealias HasAccountOnNetwork = @Sendable (NetworkID) async throws -> Bool

	public typealias UpdateAccount = @Sendable (Profile.Network.Account) async throws -> Void
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
	public func saveVirtualAccount(_ account: Profile.Network.Account) async throws {
		try await saveVirtualAccounts([account])
	}
}
