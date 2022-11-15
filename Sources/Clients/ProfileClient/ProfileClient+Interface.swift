import Collections
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
	public var setCurrentNetworkID: SetCurrentNetworkID

	/// Creates a new profile without injecting it into the ProfileClient (ProfileHolder)
	public var createNewProfile: CreateNewProfile

	public var injectProfile: InjectProfile
	public var extractProfileSnapshot: ExtractProfileSnapshot

	/// Also deletes profile and factor sources from keychain
	public var deleteProfileAndFactorSources: DeleteProfileSnapshot

	public var getAccounts: GetAccounts
	public var getBrowserExtensionConnections: GetBrowserExtensionConnections
	public var addBrowserExtensionConnection: AddBrowserExtensionConnection
	public var deleteBrowserExtensionConnection: DeleteBrowserExtensionConnection
	public var getAppPreferences: GetAppPreferences
	public var setDisplayAppPreferences: SetDisplayAppPreferences
	public var createAccount: CreateAccount
	public var lookupAccountByAddress: LookupAccountByAddress
	public var signTransaction: SignTransaction
}

public extension ProfileClient {
	typealias GetCurrentNetworkID = @Sendable () -> NetworkID
	typealias SetCurrentNetworkID = @Sendable (NetworkID) async throws -> Void

	typealias CreateNewProfile = @Sendable (CreateNewProfileRequest) async throws -> Profile

	// Async throwing because this also
	typealias InjectProfile = @Sendable (Profile) async throws -> Void

	typealias DeleteProfileSnapshot = @Sendable () async throws -> Void

	// ALL METHOD MUST BE THROWING! SINCE IF A PROFILE HAS NOT BEEN INJECTED WE SHOULD THROW AN ERROR
	typealias ExtractProfileSnapshot = @Sendable () throws -> ProfileSnapshot
	typealias GetAccounts = @Sendable () throws -> NonEmpty<OrderedSet<OnNetwork.Account>>
	typealias GetBrowserExtensionConnections = @Sendable () throws -> BrowserExtensionConnections
	typealias AddBrowserExtensionConnection = @Sendable (BrowserExtensionConnection) async throws -> Void
	typealias DeleteBrowserExtensionConnection = @Sendable (BrowserExtensionConnection.ID) async throws -> Void
	typealias GetAppPreferences = @Sendable () throws -> AppPreferences
	typealias SetDisplayAppPreferences = @Sendable (AppPreferences.Display) async throws -> Void
	typealias CreateAccount = @Sendable (CreateAccountRequest) async throws -> OnNetwork.Account
	// FIXME: Cyon will hook this up when PR https://github.com/radixdlt/babylon-wallet-ios/pull/67 is merged
	// Since it contains changes regarding NetworkID, which is now a getter and setter in ProfileClient
	typealias LookupAccountByAddress = @Sendable (AccountAddress) throws -> OnNetwork.Account
	typealias SignTransaction = @Sendable (OnNetwork.Account, TransactionManifest) async throws -> TransactionIntent.TXID
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
