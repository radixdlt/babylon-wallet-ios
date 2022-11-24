import Collections
import Dependencies
import EngineToolkit
import Foundation
import KeychainClient
import Mnemonic
import NonEmpty
import Profile
import SLIP10

public typealias MakeAccountNonVirtual = @Sendable (NetworkID) -> MakeEntityNonVirtualBySubmittingItToLedger

// MARK: - CreateNewProfileRequest
public struct CreateNewProfileRequest: Sendable, Hashable {
	public let networkAndGateway: AppPreferences.NetworkAndGateway
	public let curve25519FactorSourceMnemonic: Mnemonic
	public let nameOfFirstAccount: String?
	public let makeFirstAccountNonVirtualBySubmittingItToLedger: MakeEntityNonVirtualBySubmittingItToLedger

	public init(
		networkAndGateway: AppPreferences.NetworkAndGateway,
		curve25519FactorSourceMnemonic: Mnemonic,
		nameOfFirstAccount: String?,
		makeFirstAccountNonVirtualBySubmittingItToLedger: @escaping MakeEntityNonVirtualBySubmittingItToLedger
	) {
		self.networkAndGateway = networkAndGateway
		self.curve25519FactorSourceMnemonic = curve25519FactorSourceMnemonic
		self.nameOfFirstAccount = nameOfFirstAccount
		self.makeFirstAccountNonVirtualBySubmittingItToLedger = makeFirstAccountNonVirtualBySubmittingItToLedger
	}
}

// MARK: - ProfileClient
public struct ProfileClient: DependencyKey, Sendable {
	public var getCurrentNetworkID: GetCurrentNetworkID
	public var getGatewayAPIEndpointBaseURL: GetGatewayAPIEndpointBaseURL
	public var getNetworkAndGateway: GetNetworkAndGateway
	public var setNetworkAndGateway: SetNetworkAndGateway

	/// Creates a new profile without injecting it into the ProfileClient (ProfileHolder)
	public var createNewProfileWithOnLedgerAccount: CreateNewProfileWithOnLedgerAccount

	public var injectProfile: InjectProfile
	public var extractProfileSnapshot: ExtractProfileSnapshot

	/// Also deletes profile and factor sources from keychain
	public var deleteProfileAndFactorSources: DeleteProfileSnapshot

	public var getAccounts: GetAccounts
	public var getP2PClients: GetP2PClients
	public var addP2PClient: AddP2PClient
	public var deleteP2PClientByID: DeleteP2PClientByID
	public var getAppPreferences: GetAppPreferences
	public var setDisplayAppPreferences: SetDisplayAppPreferences
	public var createOnLedgerAccount: CreateOnLedgerAccount
	public var lookupAccountByAddress: LookupAccountByAddress

	// FIXME: - mainnet remove this and change to `async throws -> ([Prompt]) async throws -> NonEmpty<Set<Signer>>` when Profile supports multiple factor sources of different kinds.
	public var privateKeysForAddresses: PrivateKeysForAddresses
}

public extension ProfileClient {
	typealias GetGatewayAPIEndpointBaseURL = @Sendable () async -> URL
	typealias GetCurrentNetworkID = @Sendable () async -> NetworkID
	typealias SetNetworkAndGateway = @Sendable (AppPreferences.NetworkAndGateway) async throws -> Void
	typealias GetNetworkAndGateway = @Sendable () async -> AppPreferences.NetworkAndGateway

	typealias CreateNewProfileWithOnLedgerAccount = @Sendable (CreateNewProfileRequest, MakeAccountNonVirtual) async throws -> Profile

	typealias InjectProfile = @Sendable (Profile) async throws -> Void

	typealias DeleteProfileSnapshot = @Sendable () async throws -> Void

	// ALL METHOD MUST BE THROWING! SINCE IF A PROFILE HAS NOT BEEN INJECTED WE SHOULD THROW AN ERROR
	typealias ExtractProfileSnapshot = @Sendable () async throws -> ProfileSnapshot
	typealias GetAccounts = @Sendable () async throws -> NonEmpty<OrderedSet<OnNetwork.Account>>
	typealias GetP2PClients = @Sendable () async throws -> P2PClients
	typealias AddP2PClient = @Sendable (P2PClient) async throws -> Void
	typealias DeleteP2PClientByID = @Sendable (P2PClient.ID) async throws -> Void
	typealias GetAppPreferences = @Sendable () async throws -> AppPreferences
	typealias SetDisplayAppPreferences = @Sendable (AppPreferences.Display) async throws -> Void
	typealias CreateOnLedgerAccount = @Sendable (CreateOnLedgerAccountRequest) async throws -> OnNetwork.Account
	typealias LookupAccountByAddress = @Sendable (AccountAddress) async throws -> OnNetwork.Account

	// typealias SignTransaction = @Sendable (any DataProtocol, Set<OnNetwork.Account>) async throws -> Set<AccountSignature>

	typealias PrivateKeysForAddresses = @Sendable (Set<AccountAddress>) async throws -> NonEmpty<OrderedSet<PrivateKey>>
}

// MARK: - CreateOnLedgerAccountRequest
public struct CreateOnLedgerAccountRequest: Sendable, Hashable {
	public let nameOfAccount: String?
	public let makeAccountNonVirtual: MakeAccountNonVirtual
}

// MARK: - AccountSignature
public struct AccountSignature: Sendable, Hashable {
	public let account: OnNetwork.Account
	public let signature: SLIP10.Signature
}

// MARK: - CreateAnotherAccountRequest
public struct CreateAnotherAccountRequest: Sendable, Hashable {
	public let accountName: String?

	public init(
		accountName: String?
	) {
		self.accountName = accountName
	}
}
