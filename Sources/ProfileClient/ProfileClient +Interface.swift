import Collections
import ComposableArchitecture
import Foundation
import KeychainClient
import Mnemonic
import NonEmpty
import Profile

public extension KeychainClient {
	static let live = Self.live(
		accessibility: .whenPasscodeSetThisDeviceOnly
	)
}

// MARK: - KeychainClientKey
private enum KeychainClientKey: DependencyKey {
	typealias Value = KeychainClient
	static let liveValue = KeychainClient.live
	static let testValue = KeychainClient.unimplemented
}

public extension DependencyValues {
	var keychainClient: KeychainClient {
		get { self[KeychainClientKey.self] }
		set { self[KeychainClientKey.self] = newValue }
	}
}

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

public extension ProfileClient {
	static let live: Self = {
		let profileHolder = ProfileHolder.shared
		return Self(
			injectProfile: {
				profileHolder.injectProfile($0)
			},
			extractProfileSnapshot: {
				try profileHolder.takeProfileSnapshot()
			},
			deleteProfileSnapshot: {
				profileHolder.removeProfile()
			},
			getAccounts: {
				try profileHolder.get { profile in
					profile.primaryNet.accounts
				}
			},
			getAppPreferences: {
				try profileHolder.get { profile in
					profile.appPreferences
				}
			},
			setDisplayAppPreferences: { _ in
				try profileHolder.setting { _ in
				}
			},
			createAccountWithKeychainClient: { accountName, keychainClient in
				try await profileHolder.asyncSetting { profile in
					try await profile.addAccount(
						displayName: accountName,
						fromKeychainLoadOnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSource: keychainClient
					)
				}
			}
		)
	}()
}

// MARK: - ProfileHolder
private final class ProfileHolder {
	private var profile: Profile?
	private init() {}
	fileprivate static let shared = ProfileHolder()

	struct NoProfile: Swift.Error {}

	func removeProfile() {
		profile = nil
	}

	@discardableResult
	func get<T>(_ withProfile: (Profile) throws -> T) throws -> T {
		guard let profile else {
			throw NoProfile()
		}
		return try withProfile(profile)
	}

	@discardableResult
	func getAsync<T>(_ withProfile: (Profile) async throws -> T) async throws -> T {
		guard let profile else {
			throw NoProfile()
		}
		return try await withProfile(profile)
	}

	func setting(_ setProfile: (inout Profile) throws -> Void) throws {
		guard var profile else {
			throw NoProfile()
		}
		try setProfile(&profile)
		self.profile = profile
	}

	func asyncSetting<T>(_ setProfile: (inout Profile) async throws -> T) async throws -> T {
		guard var profile else {
			throw NoProfile()
		}
		let result = try await setProfile(&profile)
		self.profile = profile
		return result
	}

	func injectProfile(_ profile: Profile) {
		self.profile = profile
	}

	func takeProfileSnapshot() throws -> ProfileSnapshot {
		try get { profile in
			profile.snaphot()
		}
	}
}
