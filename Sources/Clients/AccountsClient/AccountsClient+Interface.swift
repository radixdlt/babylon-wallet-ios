import ClientPrelude
import Cryptography
import EngineKit
import Profile

// MARK: - AccountsClient
public struct AccountsClient: Sendable {
	public var getCurrentNetworkID: GetCurrentNetworkID
	public var nextAccountIndex: NextAccountIndex

	/// Accounts on current network (active gateway)
	public var getAccountsOnCurrentNetwork: GetAccountsOnCurrentNetwork

	/// Async sequence of Accounts valuues on current network (active gateway), emits new
	/// value of Accounts when you switch network (if new active gateway is on a new network).
	public var accountsOnCurrentNetwork: AccountsOnCurrentNetwork

	public var newVirtualAccount: NewVirtualAccount

	/// Saves a virtual account into the profile.
	public var saveVirtualAccount: SaveVirtualAccount

	/// Try to perform lookup of account by account address.
	public var getAccountByAddress: GetAccountByAddress

	public var getAccountsOnNetwork: GetAccountsOnNetwork

	public var hasAccountOnNetwork: HasAccountOnNetwork

	public var updateAccount: UpdateAccount

	public init(
		getCurrentNetworkID: @escaping GetCurrentNetworkID,
		nextAccountIndex: @escaping NextAccountIndex,
		getAccountsOnCurrentNetwork: @escaping GetAccountsOnCurrentNetwork,
		accountsOnCurrentNetwork: @escaping AccountsOnCurrentNetwork,
		getAccountsOnNetwork: @escaping GetAccountsOnNetwork,
		newVirtualAccount: @escaping NewVirtualAccount,
		saveVirtualAccount: @escaping SaveVirtualAccount,
		getAccountByAddress: @escaping GetAccountByAddress,
		hasAccountOnNetwork: @escaping HasAccountOnNetwork,
		updateAccount: @escaping UpdateAccount
	) {
		self.getCurrentNetworkID = getCurrentNetworkID
		self.nextAccountIndex = nextAccountIndex
		self.getAccountsOnCurrentNetwork = getAccountsOnCurrentNetwork
		self.getAccountsOnNetwork = getAccountsOnNetwork
		self.accountsOnCurrentNetwork = accountsOnCurrentNetwork
		self.newVirtualAccount = newVirtualAccount
		self.saveVirtualAccount = saveVirtualAccount
		self.getAccountByAddress = getAccountByAddress
		self.hasAccountOnNetwork = hasAccountOnNetwork
		self.updateAccount = updateAccount
	}
}

extension AccountsClient {
	public typealias GetCurrentNetworkID = @Sendable () async -> NetworkID
	public typealias NextAccountIndex = @Sendable (NetworkID?) async -> HD.Path.Component.Child.Value
	public typealias GetAccountsOnCurrentNetwork = @Sendable () async throws -> Profile.Network.Accounts
	public typealias GetAccountsOnNetwork = @Sendable (NetworkID) async throws -> Profile.Network.Accounts

	public typealias AccountsOnCurrentNetwork = @Sendable () async -> AnyAsyncSequence<Profile.Network.Accounts>

	public typealias NewVirtualAccount = @Sendable (NewAccountRequest) async throws -> Profile.Network.Account
	public typealias SaveVirtualAccount = @Sendable (SaveAccountRequest) async throws -> Void

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

// MARK: - SaveAccountRequest
public struct SaveAccountRequest: Sendable, Hashable {
	public let account: Profile.Network.Account
	public init(account: Profile.Network.Account) {
		self.account = account
	}
}
