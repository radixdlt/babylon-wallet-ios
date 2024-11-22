import IdentifiedCollections
import Sargon

// MARK: - AccountsClient
struct AccountsClient: Sendable {
	var getCurrentNetworkID: GetCurrentNetworkID
	var nextAppearanceID: NextAppearanceID

	/// Accounts on current network (active gateway)
	var getAccountsOnCurrentNetwork: GetAccountsOnCurrentNetwork

	var getHiddenAccountsOnCurrentNetwork: GetHiddenAccountsOnCurrentNetwork

	/// Async sequence of Accounts values on current network (active gateway), emits new
	/// value of Accounts when you switch network (if new active gateway is on a new network).
	var accountsOnCurrentNetwork: AccountsOnCurrentNetwork

	/// Allows subscribing to any account updates
	var accountUpdates: AccountUpdates

	var newVirtualAccount: NewVirtualAccount

	/// Saves virtual accounts into the profile.
	var saveVirtualAccounts: SaveVirtualAccounts

	/// Try to perform lookup of account by account address.
	var getAccountByAddress: GetAccountByAddress

	var getAccountsOnNetwork: GetAccountsOnNetwork

	var hasAccountOnNetwork: HasAccountOnNetwork

	var updateAccount: UpdateAccount
}

extension AccountsClient {
	typealias GetCurrentNetworkID = @Sendable () async -> NetworkID

	typealias NextAppearanceID = @Sendable (NetworkID?, _ offset: Int?) async -> AppearanceID

	typealias GetAccountsOnCurrentNetwork = @Sendable () async throws -> Accounts
	typealias GetHiddenAccountsOnCurrentNetwork = @Sendable () async throws -> Accounts
	typealias GetAccountsOnNetwork = @Sendable (NetworkID) async throws -> Accounts

	typealias AccountsOnCurrentNetwork = @Sendable () async -> AnyAsyncSequence<Accounts>
	typealias AccountUpdates = @Sendable (AccountAddress) async -> AnyAsyncSequence<Account>

	typealias NewVirtualAccount = @Sendable (NewAccountRequest) async throws -> Account
	typealias SaveVirtualAccounts = @Sendable (Accounts) async throws -> Void

	typealias GetAccountByAddress = @Sendable (AccountAddress) async throws -> Account

	typealias HasAccountOnNetwork = @Sendable (NetworkID) async throws -> Bool

	typealias UpdateAccount = @Sendable (Account) async throws -> Void
}

// MARK: - NewAccountRequest
struct NewAccountRequest: Sendable, Hashable {
	let name: NonEmptyString
	let factorInstance: HierarchicalDeterministicFactorInstance
	let networkID: NetworkID
}

extension AccountsClient {
	/// Saves a virtual account into the profile.
	func saveVirtualAccount(_ account: Account) async throws {
		try await saveVirtualAccounts([account])
	}

	func isLedgerHWAccount(_ address: AccountAddress) async -> Bool {
		do {
			let account = try await getAccountByAddress(address)
			return account.isLedgerControlled
		} catch {
			return false
		}
	}
}
