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

	public init(
		getAccountsOnCurrentNetwork: @escaping GetAccountsOnCurrentNetwork,
		accountsOnCurrentNetwork: @escaping AccountsOnCurrentNetwork,
		createUnsavedVirtualAccount: @escaping CreateUnsavedVirtualAccount,
		saveVirtualAccount: @escaping SaveVirtualAccount,
		getAccountByAddress: @escaping GetAccountByAddress
	) {
		self.getAccountsOnCurrentNetwork = getAccountsOnCurrentNetwork
		self.accountsOnCurrentNetwork = accountsOnCurrentNetwork
		self.createUnsavedVirtualAccount = createUnsavedVirtualAccount
		self.saveVirtualAccount = saveVirtualAccount
		self.getAccountByAddress = getAccountByAddress
	}
}

extension AccountsClient {
	public typealias GetAccountsOnCurrentNetwork = @Sendable () async -> OnNetwork.Accounts

	public typealias AccountsOnCurrentNetwork = @Sendable () async -> AnyAsyncSequence<OnNetwork.Accounts>

	public typealias CreateUnsavedVirtualAccount = @Sendable (CreateVirtualAccountRequest) async throws -> OnNetwork.Account
	public typealias SaveVirtualAccount = @Sendable (OnNetwork.Account) async throws -> Void

	public typealias GetAccountByAddress = @Sendable (AccountAddress) async throws -> OnNetwork.Account
}

// MARK: - CreateVirtualAccountRequest
public struct CreateVirtualAccountRequest: CreateVirtualEntityRequestProtocol, Equatable {
	// if `nil` we will use current networkID
	public let networkID: NetworkID?

	// FIXME: change to shared HDFactorSource
	public let genesisFactorInstanceDerivationStrategy: GenesisFactorInstanceDerivationStrategy

	public let curve: Slip10Curve
	public let displayName: NonEmpty<String>
	public var entityKind: EntityKind { .account }

	public init(
		curve: Slip10Curve,
		networkID: NetworkID?,
		genesisFactorInstanceDerivationStrategy: GenesisFactorInstanceDerivationStrategy,
		displayName: NonEmpty<String>
	) throws {
		self.curve = curve
		self.networkID = networkID
		self.genesisFactorInstanceDerivationStrategy = genesisFactorInstanceDerivationStrategy
		self.displayName = displayName
	}
}
