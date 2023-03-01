import ClientPrelude
import Cryptography
import Profile

// MARK: - AccountsClient
public struct AccountsClient: Sendable {
	public var getAccountsOnCurrentNetwork: GetAccountsOnCurrentNetwork
	public var accountsOnCurrentNetwork: AccountsOnCurrentNetwork
	public var createUnsavedVirtualAccount: CreateUnsavedVirtualAccount
	public var saveVirtualAccount: SaveVirtualAccount

	public init(
		getAccountsOnCurrentNetwork: @escaping GetAccountsOnCurrentNetwork,
		accountsOnCurrentNetwork: @escaping AccountsOnCurrentNetwork,
		createUnsavedVirtualAccount: @escaping CreateUnsavedVirtualAccount,
		saveVirtualAccount: @escaping SaveVirtualAccount
	) {
		self.getAccountsOnCurrentNetwork = getAccountsOnCurrentNetwork
		self.accountsOnCurrentNetwork = accountsOnCurrentNetwork
		self.createUnsavedVirtualAccount = createUnsavedVirtualAccount
		self.saveVirtualAccount = saveVirtualAccount
	}
}

extension AccountsClient {
	/// Accounts on current network (active gateway)
	public typealias GetAccountsOnCurrentNetwork = @Sendable () async -> OnNetwork.Accounts

	/// Async sequence of Accounts valuues on current network (active gateway), emits new
	/// value of Accounts when you switch network (if new active gateway is on a new network).
	public typealias AccountsOnCurrentNetwork = @Sendable () async -> AnyAsyncSequence<OnNetwork.Accounts>

	public typealias CreateUnsavedVirtualAccount = @Sendable (CreateVirtualAccountRequest) async throws -> OnNetwork.Account
	public typealias SaveVirtualAccount = @Sendable (OnNetwork.Account) async throws -> Void
}

// MARK: - CreateVirtualAccountRequest
public struct CreateVirtualAccountRequest: CreateVirtualEntityRequest, Equatable {
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
