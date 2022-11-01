import Collections
import Dependencies
import EngineToolkit
import Foundation
import KeychainClient
import Mnemonic
import NonEmpty
import Profile

// MARK: - CreateNewProfileRequest
public struct CreateNewProfileRequest {
	public let curve25519FactorSourceMnemonic: Mnemonic
	public let createFirstAccountRequest: CreateAccountRequest
	public init(curve25519FactorSourceMnemonic: Mnemonic, createFirstAccountRequest: CreateAccountRequest) {
		self.curve25519FactorSourceMnemonic = curve25519FactorSourceMnemonic
		self.createFirstAccountRequest = createFirstAccountRequest
	}
}

// MARK: - ProfileClient
public struct ProfileClient: DependencyKey {
	/// Creates a new profile without injecting it into the ProfileClient (ProfileHolder)
	public var createNewProfile: CreateNewProfile

	public var injectProfile: InjectProfile
	public var extractProfileSnapshot: ExtractProfileSnapshot

	/// Does NOT delete the ProfileSnapshot from keychain, you have to do that elsewhere.
	public var deleteProfileSnapshot: DeleteProfileSnapshot

	public var getAccounts: GetAccounts
	public var getAppPreferences: GetAppPreferences
	public var setDisplayAppPreferences: SetDisplayAppPreferences
	public var createAccount: CreateAccount
	public var lookupAccountByAddress: LookupAccountByAddress
	public var signTransaction: SignTransaction
}

public extension ProfileClient {
	/// For when profile already exists
	typealias CreateNewProfile = @Sendable (CreateNewProfileRequest) async throws -> Profile
	typealias InjectProfile = @Sendable (Profile) -> Void
	typealias DeleteProfileSnapshot = @Sendable () throws -> Void

	// ALL METHOD MUST BE THROWING! SINCE IF A PROFILE HAS NOT BEEN INJECTED WE SHOULD THROW AN ERROR
	typealias ExtractProfileSnapshot = @Sendable () throws -> ProfileSnapshot
	typealias GetAccounts = @Sendable () throws -> NonEmpty<OrderedSet<OnNetwork.Account>>
	typealias GetAppPreferences = @Sendable () throws -> AppPreferences
	typealias SetDisplayAppPreferences = @Sendable (AppPreferences.Display) throws -> Void
	typealias CreateAccount = @Sendable (CreateAccountRequest) async throws -> OnNetwork.Account
	// FIXME: Cyon will hook this up when PR https://github.com/radixdlt/babylon-wallet-ios/pull/67 is merged
	// Since it contains changes regarding NetworkID, which is now a getter and setter in ProfileClient
	typealias LookupAccountByAddress = @Sendable (String) throws -> OnNetwork.Account
	typealias SignTransaction = @Sendable (OnNetwork.Account.ID, TransactionManifest) async throws -> TXID
	// ALL METHOD MUST BE THROWING! SINCE IF A PROFILE HAS NOT BEEN INJECTED WE SHOULD THROW AN ERROR
}

public typealias TXID = String // TODO: replace with real Transaction.ID

// MARK: - CreateAccountRequest
public struct CreateAccountRequest {
	public let accountName: String?
	public let networkID: NetworkID
	/// Used to read out secrets
	public let keychainClient: KeychainClient

	public init(
		accountName: String?,
		keychainClient: KeychainClient,
		networkID: NetworkID
	) {
		self.accountName = accountName
		self.keychainClient = keychainClient
		self.networkID = networkID
	}
}
