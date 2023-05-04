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

	/// Creates a new virtual account controlled by a `device` factor source, without saving it into the profile
	public var newUnsavedVirtualAccountControlledByDeviceFactorSource: NewUnsavedVirtualAccountControlledByDeviceFactorSource

	/// Creates a new virtual account controlled by a `ledger` factor source, without saving it into the profile
	public var newUnsavedVirtualAccountControlledByLedgerFactorSource: NewUnsavedVirtualAccountControlledByLedgerFactorSource

	/// Saves a virtual account into the profile.
	public var saveVirtualAccount: SaveVirtualAccount

	/// Try to perform lookup of account by account address.
	public var getAccountByAddress: GetAccountByAddress

	public var getAccountsOnNetwork: GetAccountsOnNetwork

	public var hasAccountOnNetwork: HasAccountOnNetwork

	public var updateAccount: UpdateAccount

	public init(
		getAccountsOnCurrentNetwork: @escaping GetAccountsOnCurrentNetwork,
		accountsOnCurrentNetwork: @escaping AccountsOnCurrentNetwork,
		getAccountsOnNetwork: @escaping GetAccountsOnNetwork,
		newUnsavedVirtualAccountControlledByDeviceFactorSource: @escaping NewUnsavedVirtualAccountControlledByDeviceFactorSource,
		newUnsavedVirtualAccountControlledByLedgerFactorSource: @escaping NewUnsavedVirtualAccountControlledByLedgerFactorSource,
		saveVirtualAccount: @escaping SaveVirtualAccount,
		getAccountByAddress: @escaping GetAccountByAddress,
		hasAccountOnNetwork: @escaping HasAccountOnNetwork,
		updateAccount: @escaping UpdateAccount
	) {
		self.getAccountsOnCurrentNetwork = getAccountsOnCurrentNetwork
		self.getAccountsOnNetwork = getAccountsOnNetwork
		self.accountsOnCurrentNetwork = accountsOnCurrentNetwork
		self.newUnsavedVirtualAccountControlledByDeviceFactorSource = newUnsavedVirtualAccountControlledByDeviceFactorSource
		self.newUnsavedVirtualAccountControlledByLedgerFactorSource = newUnsavedVirtualAccountControlledByLedgerFactorSource
		self.saveVirtualAccount = saveVirtualAccount
		self.getAccountByAddress = getAccountByAddress
		self.hasAccountOnNetwork = hasAccountOnNetwork
		self.updateAccount = updateAccount
	}
}

extension AccountsClient {
	public typealias GetAccountsOnCurrentNetwork = @Sendable () async throws -> Profile.Network.Accounts
	public typealias GetAccountsOnNetwork = @Sendable (NetworkID) async throws -> Profile.Network.Accounts

	public typealias AccountsOnCurrentNetwork = @Sendable () async -> AnyAsyncSequence<Profile.Network.Accounts>

	public typealias NewUnsavedVirtualAccountControlledByDeviceFactorSource = @Sendable (CreateVirtualEntityControlledByDeviceFactorSourceRequest) async throws -> Profile.Network.Account

	public typealias NewUnsavedVirtualAccountControlledByLedgerFactorSource = @Sendable (CreateVirtualEntityControlledByLedgerFactorSourceRequest) async throws -> Profile.Network.Account

	public typealias SaveVirtualAccount = @Sendable (SaveAccountRequest) async throws -> Void

	public typealias GetAccountByAddress = @Sendable (AccountAddress) async throws -> Profile.Network.Account

	public typealias HasAccountOnNetwork = @Sendable (NetworkID) async throws -> Bool

	public typealias UpdateAccount = @Sendable (Profile.Network.Account) async throws -> Void
}

// MARK: - SaveAccountRequest
public struct SaveAccountRequest: Sendable, Hashable {
	public let account: Profile.Network.Account
	public let shouldUpdateFactorSourceNextDerivationIndex: Bool
	public init(account: Profile.Network.Account, shouldUpdateFactorSourceNextDerivationIndex: Bool) {
		self.account = account
		self.shouldUpdateFactorSourceNextDerivationIndex = shouldUpdateFactorSourceNextDerivationIndex
	}
}
