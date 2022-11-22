import Collections
import EngineToolkit
import Foundation
import KeychainClient
import Mnemonic
import NonEmpty
import Profile

public typealias MakeAccountNonVirtual = @Sendable (CreateAccountRequest) -> MakeEntityNonVirtualBySubmittingItToLedger

// MARK: - CreateNewProfileRequest
public struct CreateNewProfileRequest {
	public let curve25519FactorSourceMnemonic: Mnemonic
	public let createFirstAccountRequest: CreateAccountRequest

	public init(
		curve25519FactorSourceMnemonic: Mnemonic,
		createFirstAccountRequest: CreateAccountRequest
	) {
		self.curve25519FactorSourceMnemonic = curve25519FactorSourceMnemonic
		self.createFirstAccountRequest = createFirstAccountRequest
	}
}

// MARK: - ProfileClient
public struct ProfileClient {
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
	public var signTransaction: SignTransaction
}

public extension ProfileClient {
	typealias GetGatewayAPIEndpointBaseURL = @Sendable () async -> URL
	typealias GetCurrentNetworkID = @Sendable () async -> NetworkID
	typealias SetNetworkAndGateway = @Sendable (AppPreferences.NetworkAndGateway) async throws -> Void
	typealias GetNetworkAndGateway = @Sendable () async -> AppPreferences.NetworkAndGateway

	typealias CreateNewProfileWithOnLedgerAccount = @Sendable (CreateNewProfileRequest, MakeAccountNonVirtual) async throws -> Profile

	// Async throwing because this also
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
	typealias CreateOnLedgerAccount = @Sendable (CreateAccountRequest, MakeAccountNonVirtual) async throws -> OnNetwork.Account
	// FIXME: Cyon will hook this up when PR https://github.com/radixdlt/babylon-wallet-ios/pull/67 is merged
	// Since it contains changes regarding NetworkID, which is now a getter and setter in ProfileClient
	typealias LookupAccountByAddress = @Sendable (AccountAddress) async throws -> OnNetwork.Account
	typealias SignTransaction = @Sendable (TransactionManifest) async throws -> TransactionIntent.TXID
	// ALL METHOD MUST BE THROWING! SINCE IF A PROFILE HAS NOT BEEN INJECTED WE SHOULD THROW AN ERROR
}

// MARK: - CreateAccountRequest
public struct CreateAccountRequest {
	public let accountName: String?

	public init(
		accountName: String?
	) {
		self.accountName = accountName
	}
}
