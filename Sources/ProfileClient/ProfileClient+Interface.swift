import Collections
import ComposableArchitecture
import Foundation
import KeychainClient
import Mnemonic
import NonEmpty
import Profile

// MARK: - ProfileClient
public struct ProfileClient {
	public var injectProfile: InjectProfile
	public var extractProfileSnapshot: ExtractProfileSnapshot

	/// Does NOT delete the ProfileSnapshot from keychain, you have to do that elsewhere.
	public var deleteProfileSnapshot: DeleteProfileSnapshot

	public var getAccounts: GetAccounts
	public var getAppPreferences: GetAppPreferences
	public var setDisplayAppPreferences: SetDisplayAppPreferences
	public var createAccountWithKeychainClient: CreateAccountWithKeychainClient
}

public extension ProfileClient {
	typealias InjectProfile = @Sendable (Profile) -> Void
	typealias DeleteProfileSnapshot = @Sendable () throws -> Void

	// ALL METHOD MUST BE THROWING! SINCE IF A PROFILE HAS NOT BEEN INJECTED WE SHOULD THROW AN ERROR
	typealias ExtractProfileSnapshot = @Sendable () throws -> ProfileSnapshot
	typealias GetAccounts = @Sendable () throws -> NonEmpty<OrderedSet<OnNetwork.Account>>
	typealias GetAppPreferences = @Sendable () throws -> AppPreferences
	typealias SetDisplayAppPreferences = @Sendable (AppPreferences.Display) throws -> Void
	typealias CreateAccountWithKeychainClient = @Sendable (_ accountName: String?, KeychainClient) async throws -> OnNetwork.Account
	// ALL METHOD MUST BE THROWING! SINCE IF A PROFILE HAS NOT BEEN INJECTED WE SHOULD THROW AN ERROR
}
