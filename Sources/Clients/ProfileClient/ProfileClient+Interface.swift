import Collections
import Dependencies
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
public struct ProfileClient: DependencyKey {
	public var getCurrentNetworkID: GetCurrentNetworkID
	public var setCurrentNetworkID: SetCurrentNetworkID

	/// Creates a new profile without injecting it into the ProfileClient (ProfileHolder)
	public var createNewProfile: CreateNewProfile

	public var injectProfile: InjectProfile
	public var extractProfileSnapshot: ExtractProfileSnapshot

	/// Does NOT delete the ProfileSnapshot from keychain, you have to do that elsewhere.
	public var deleteProfileSnapshot: DeleteProfileSnapshot

	public var getAccounts: GetAccounts
	public var getBrowserExtensionConnections: GetBrowserExtensionConnections
	public var addBrowserExtensionConnection: AddBrowserExtensionConnection
	public var deleteBrowserExtensionConnection: DeleteBrowserExtensionConnection
	public var getAppPreferences: GetAppPreferences
	public var setDisplayAppPreferences: SetDisplayAppPreferences
	public var createAccount: CreateAccount
}

public extension ProfileClient {
	typealias GetCurrentNetworkID = @Sendable () -> NetworkID
	typealias SetCurrentNetworkID = @Sendable (NetworkID) async throws -> Void

	typealias CreateNewProfile = @Sendable (CreateNewProfileRequest) async throws -> Profile

	// Async throwing because this also
	typealias InjectProfile = @Sendable (Profile, InjectProfileMode) async throws -> Void

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
	// ALL METHOD MUST BE THROWING! SINCE IF A PROFILE HAS NOT BEEN INJECTED WE SHOULD THROW AN ERROR
}

// MARK: - InjectProfileMode
public enum InjectProfileMode {
	case onlyInject
	case injectAndPersistInKeychain
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
