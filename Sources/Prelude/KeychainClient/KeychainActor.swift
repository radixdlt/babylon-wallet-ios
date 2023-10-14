import Foundation
import KeychainAccess

// MARK: - KeychainActor
@_spi(KeychainInternal)
public final actor KeychainActor: GlobalActor {
	@_spi(KeychainInternal)
	public static let shared = KeychainActor()

	private let keychain: Keychain
	private nonisolated let service: String
	private nonisolated let accessGroup: String?

	private init() {
		var defaultService = "Radix Wallet" // DO NOT CHANGE THIS EVER
		#if DEBUG
		defaultService += " DEBUG"
		#endif
		self.keychain = Keychain(service: defaultService)
		self.service = keychain.service
		self.accessGroup = keychain.accessGroup
	}
}

extension KeychainActor {
	@_spi(KeychainInternal)
	public typealias Key = KeychainClient.Key
	@_spi(KeychainInternal)
	public typealias Label = KeychainClient.Label
	@_spi(KeychainInternal)
	public typealias Comment = KeychainClient.Comment
	@_spi(KeychainInternal)
	public typealias AuthenticationPrompt = KeychainClient.AuthenticationPrompt
}

extension KeychainActor {
	public nonisolated func getServiceAndAccessGroup() -> (service: String, accessGroup: String?) {
		(service, accessGroup)
	}

	/// Checks if keychain contains an item without prompting showing Auth Prompt
	/// even for items that require auth (if you dont explictily set `showAuthPrompt: true`)
	@_spi(KeychainInternal)
	public func contains(
		_ key: Key,
		showAuthPrompt: Bool = false
	) async throws -> Bool {
		try keychain.contains(key.rawValue.rawValue, withoutAuthenticationUI: !showAuthPrompt)
	}

	@_spi(KeychainInternal)
	public func setDataWithoutAuth(
		_ data: Data,
		forKey key: Key,
		attributes: KeychainClient.AttributesWithoutAuth
	) async throws {
		try withAttributes(of: attributes)
			.set(data, key: key.rawValue.rawValue)
	}

	@_spi(KeychainInternal)
	public func setDataWithAuth(
		_ data: Data,
		forKey key: Key,
		attributes: KeychainClient.AttributesWithAuth
	) async throws {
		try withAttributes(of: attributes)
			.set(data, key: key.rawValue.rawValue)
	}

	@_spi(KeychainInternal)
	public func getDataWithoutAuthForKeySetIfNil(
		forKey key: Key,
		ifNilSet: KeychainClient.IfNilSetWithoutAuth
	) async throws -> (value: Data, wasNil: Bool) {
		if let value = try await getDataWithoutAuth(forKey: key) {
			return (value, wasNil: false)
		} else {
			let value = ifNilSet.value
			try await setDataWithoutAuth(value, forKey: key, attributes: ifNilSet.attributes)
			return (value, wasNil: true)
		}
	}

	@_spi(KeychainInternal)
	public func getDataWithAuthForKeySetIfNil(
		forKey key: Key,
		authenticationPrompt: AuthenticationPrompt,
		ifNilSet: KeychainClient.IfNilSetWithAuth
	) async throws -> (value: Data, wasNil: Bool) {
		if let value = try await getDataWithAuth(
			forKey: key,
			authenticationPrompt: authenticationPrompt
		) {
			return (value, wasNil: false)
		} else {
			let value = ifNilSet.value
			try await setDataWithAuth(value, forKey: key, attributes: ifNilSet.attributes)
			return (value, wasNil: true)
		}
	}

	@_spi(KeychainInternal)
	public func getDataWithoutAuth(
		forKey key: Key
	) async throws -> Data? {
		try keychain.getData(key.rawValue.rawValue)
	}

	@_spi(KeychainInternal)
	public func getDataWithAuth(
		forKey key: Key,
		authenticationPrompt: AuthenticationPrompt
	) async throws -> Data? {
		try keychain
			.authenticationPrompt(authenticationPrompt.rawValue.rawValue)
			.getData(key.rawValue.rawValue)
	}

	@_spi(KeychainInternal)
	public func removeData(
		forKey key: Key
	) async throws {
		try keychain.remove(key.rawValue.rawValue)
	}

	@_spi(KeychainInternal)
	public func removeAllItems() async throws {
		try keychain.removeAll()
	}
}

// MARK: Private
extension KeychainActor {
	private func withAttributes(
		of attributes: KeychainAttributes
	) -> Keychain {
		var handle = keychain.synchronizable(attributes.iCloudSyncEnabled)
		if let label = attributes.label {
			handle = handle.label(label.rawValue.rawValue)
		}
		if let comment = attributes.comment {
			handle = handle.comment(comment.rawValue.rawValue)
		}
		let accessibility = attributes.accessibility
		if let authenticationPolicy = (attributes as? KeychainClient.AttributesWithAuth)?.authenticationPolicy {
			handle = handle.accessibility(accessibility, authenticationPolicy: authenticationPolicy)
		} else {
			handle = handle.accessibility(accessibility)
		}
		return handle
	}
}

// MARK: - KeychainAccess.AuthenticationPolicy + Hashable
extension KeychainAccess.AuthenticationPolicy: Hashable {}
