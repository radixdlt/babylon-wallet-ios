private let keychainService = {
	var defaultService = "Radix Wallet" // DO NOT CHANGE THIS EVER
	#if DEBUG
	defaultService += " DEBUG"
	#endif
	return defaultService
}()

// MARK: - KeychainHolder
@_spi(KeychainInternal)
public final class KeychainHolder: @unchecked Sendable {
	@_spi(KeychainInternal)
	public static let shared = KeychainHolder()

	private let keychain: Keychain
	private let service: String
	private let accessGroup: String?

	private init() {
		self.keychain = Keychain(service: keychainService)
		self.service = keychain.service
		self.accessGroup = keychain.accessGroup
	}
}

extension KeychainHolder {
	@_spi(KeychainInternal)
	public typealias Key = KeychainClient.Key
	@_spi(KeychainInternal)
	public typealias Label = KeychainClient.Label
	@_spi(KeychainInternal)
	public typealias Comment = KeychainClient.Comment
	@_spi(KeychainInternal)
	public typealias AuthenticationPrompt = KeychainClient.AuthenticationPrompt

	public func getServiceAndAccessGroup() -> (service: String, accessGroup: String?) {
		(service, accessGroup)
	}

	/// Checks if keychain contains an item without prompting showing Auth Prompt
	/// even for items that require auth (if you dont explictily set `showAuthPrompt: true`)
	@_spi(KeychainInternal)
	public func contains(
		_ key: Key,
		showAuthPrompt: Bool = false
	) throws -> Bool {
		try keychain.contains(key.rawValue.rawValue, withoutAuthenticationUI: !showAuthPrompt)
	}
}

extension KeychainHolder {
	@_spi(KeychainInternal)
	public func setDataWithoutAuth(
		_ data: Data,
		forKey key: Key,
		attributes: KeychainClient.AttributesWithoutAuth
	) throws {
		try withAttributes(of: attributes)
			.set(data, key: key.rawValue.rawValue)
	}

	@_spi(KeychainInternal)
	public func setDataWithAuth(
		_ data: Data,
		forKey key: Key,
		attributes: KeychainClient.AttributesWithAuth
	) throws {
		try withAttributes(of: attributes)
			.set(data, key: key.rawValue.rawValue)
	}

	@_spi(KeychainInternal)
	public func getDataWithoutAuth(
		forKey key: Key,
		ifNilSet: KeychainClient.IfNilSetWithoutAuth
	) throws -> (value: Data, wasNil: Bool) {
		if let value = try getDataWithoutAuth(forKey: key) {
			return (value, wasNil: false)
		} else {
			let value = try ifNilSet.getValueToSet()
			try setDataWithoutAuth(value, forKey: key, attributes: ifNilSet.attributes)
			return (value, wasNil: true)
		}
	}

	@_spi(KeychainInternal)
	public func getDataWithAuth(
		forKey key: Key,
		authenticationPrompt: AuthenticationPrompt,
		ifNilSet: KeychainClient.IfNilSetWithAuth
	) throws -> (value: Data, wasNil: Bool) {
		if let value = try getDataWithAuth(
			forKey: key,
			authenticationPrompt: authenticationPrompt
		) {
			return (value, wasNil: false)
		} else {
			let value = try ifNilSet.getValueToSet()
			try setDataWithAuth(value, forKey: key, attributes: ifNilSet.attributes)
			return (value, wasNil: true)
		}
	}

	@_spi(KeychainInternal)
	public func getDataWithoutAuth(
		forKey key: Key
	) throws -> Data? {
		try keychain.getData(key.rawValue.rawValue)
	}

	@_spi(KeychainInternal)
	public func getDataWithAuth(
		forKey key: Key,
		authenticationPrompt: AuthenticationPrompt
	) throws -> Data? {
		try keychain
			.authenticationPrompt(authenticationPrompt.rawValue.rawValue)
			.getData(key.rawValue.rawValue)
	}

	@_spi(KeychainInternal)
	public func removeData(
		forKey key: Key
	) throws {
		try keychain.remove(key.rawValue.rawValue)
	}

	@_spi(KeychainInternal)
	public func removeAllItems() throws {
		try keychain.removeAll()
	}
}

// MARK: Private
extension KeychainHolder {
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
