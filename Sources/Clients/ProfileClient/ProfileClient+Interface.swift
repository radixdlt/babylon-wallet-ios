import ClientPrelude
import Cryptography
import EngineToolkit
import P2PModels
import Profile

// MARK: - CreateNewProfileRequest
public struct CreateNewProfileRequest: Sendable {
	public let networkAndGateway: AppPreferences.NetworkAndGateway
	public let curve25519FactorSourceMnemonic: Mnemonic
	public let nameOfFirstAccount: String?

	public init(
		networkAndGateway: AppPreferences.NetworkAndGateway,
		curve25519FactorSourceMnemonic: Mnemonic,
		nameOfFirstAccount: String?
	) {
		self.networkAndGateway = networkAndGateway
		self.curve25519FactorSourceMnemonic = curve25519FactorSourceMnemonic
		self.nameOfFirstAccount = nameOfFirstAccount
	}
}

// MARK: - ProfileClient
public struct ProfileClient: DependencyKey, Sendable {
	public var getCurrentNetworkID: GetCurrentNetworkID
	public var getGatewayAPIEndpointBaseURL: GetGatewayAPIEndpointBaseURL
	public var getNetworkAndGateway: GetNetworkAndGateway
	public var setNetworkAndGateway: SetNetworkAndGateway

	/// Creates a new profile without injecting it into the ProfileClient (ProfileHolder)
	public var createNewProfile: CreateNewProfile

	public var injectProfile: InjectProfile
	public var extractProfileSnapshot: ExtractProfileSnapshot

	/// Also deletes profile and factor sources from keychain
	public var deleteProfileAndFactorSources: DeleteProfileSnapshot

	public var hasAccountOnNetwork: HasAccountOnNetwork
	public var getAccounts: GetAccounts
	public var getP2PClients: GetP2PClients
	public var addP2PClient: AddP2PClient
	public var deleteP2PClientByID: DeleteP2PClientByID
	public var getAppPreferences: GetAppPreferences
	public var setDisplayAppPreferences: SetDisplayAppPreferences
	public var createVirtualAccount: CreateVirtualAccount
	public var lookupAccountByAddress: LookupAccountByAddress

	public var signersForAccountsGivenAddresses: SignersForAccountsGivenAddresses
}

// MARK: - SignersForAccountsGivenAddressesRequest
public struct SignersForAccountsGivenAddressesRequest: Sendable, Hashable {
	public let keychainAccessFactorSourcesAuthPrompt: String

	// Might be empty! And in case of empty...
	public let addresses: OrderedSet<AccountAddress>
	// ... we will use this NetworkID to get the first account and used that to sign
	public let networkID: NetworkID

	public init(
		networkID: NetworkID,
		addresses: OrderedSet<AccountAddress>,
		keychainAccessFactorSourcesAuthPrompt: String
	) {
		self.networkID = networkID
		self.addresses = addresses
		self.keychainAccessFactorSourcesAuthPrompt = keychainAccessFactorSourcesAuthPrompt
	}
}

public extension ProfileClient {
	typealias GetGatewayAPIEndpointBaseURL = @Sendable () async -> URL
	typealias GetCurrentNetworkID = @Sendable () async -> NetworkID

	typealias SetNetworkAndGateway = @Sendable (AppPreferences.NetworkAndGateway) async throws -> Void

	typealias GetNetworkAndGateway = @Sendable () async -> AppPreferences.NetworkAndGateway

	typealias CreateNewProfile = @Sendable (CreateNewProfileRequest) async throws -> Profile

	typealias InjectProfile = @Sendable (Profile) async throws -> Void

	typealias DeleteProfileSnapshot = @Sendable () async throws -> Void

	// ALL METHOD MUST BE THROWING! SINCE IF A PROFILE HAS NOT BEEN INJECTED WE SHOULD THROW AN ERROR
	typealias ExtractProfileSnapshot = @Sendable () async throws -> ProfileSnapshot
	typealias HasAccountOnNetwork = @Sendable (NetworkID) async throws -> Bool
	typealias GetAccounts = @Sendable () async throws -> NonEmpty<OrderedSet<OnNetwork.Account>>
	typealias GetP2PClients = @Sendable () async throws -> P2PClients
	typealias AddP2PClient = @Sendable (P2PClient) async throws -> Void
	typealias DeleteP2PClientByID = @Sendable (P2PClient.ID) async throws -> Void
	typealias GetAppPreferences = @Sendable () async throws -> AppPreferences
	typealias SetDisplayAppPreferences = @Sendable (AppPreferences.Display) async throws -> Void
	typealias CreateVirtualAccount = @Sendable (CreateAccountRequest) async throws -> OnNetwork.Account
	typealias LookupAccountByAddress = @Sendable (AccountAddress) async throws -> OnNetwork.Account

	typealias SignersForAccountsGivenAddresses = @Sendable (SignersForAccountsGivenAddressesRequest) async throws -> NonEmpty<OrderedSet<SignersOfAccount>>
}

public typealias SignersOfAccount = SignersOf<OnNetwork.Account>

// MARK: - AccountSignature
public struct AccountSignature: Sendable, Hashable {
	public let account: OnNetwork.Account
	public let signature: SLIP10.Signature
}

// MARK: - CreateAccountRequest
public struct CreateAccountRequest: Sendable, Hashable {
	public let overridingNetworkID: NetworkID?
	public let keychainAccessFactorSourcesAuthPrompt: String
	public let accountName: String?

	public init(
		overridingNetworkID: NetworkID?,
		keychainAccessFactorSourcesAuthPrompt: String,
		accountName: String?
	) {
		self.overridingNetworkID = overridingNetworkID
		self.keychainAccessFactorSourcesAuthPrompt = keychainAccessFactorSourcesAuthPrompt
		self.accountName = accountName
	}
}
