#if DEBUG
private let keychainService = "Radix Wallet DEBUG"
#else
// DO NOT CHANGE THIS EVER
private let keychainService = "Radix Wallet"
#endif

// MARK: - KeychainHolder
final class KeychainHolder: @unchecked Sendable {
	static let shared = KeychainHolder()

	private let keychain: Keychain
	private let service: String
	private let accessGroup: String?
	private let keychainChangedSubject = AsyncPassthroughSubject<Void>()

	private init() {
		self.keychain = Keychain(service: keychainService)
		self.service = keychain.service
		self.accessGroup = keychain.accessGroup
	}
}

extension KeychainHolder {
	typealias Key = KeychainClient.Key
	typealias Label = KeychainClient.Label
	typealias Comment = KeychainClient.Comment
	typealias AuthenticationPrompt = KeychainClient.AuthenticationPrompt

	var keychainChanged: AnyAsyncSequence<Void> {
		keychainChangedSubject.eraseToAnyAsyncSequence()
	}

	func getServiceAndAccessGroup() -> (service: String, accessGroup: String?) {
		(service, accessGroup)
	}

	/// Checks if keychain contains an item without prompting showing Auth Prompt
	/// even for items that require auth (if you dont explictily set `showAuthPrompt: true`)
	func contains(
		_ key: Key,
		showAuthPrompt: Bool = false
	) throws -> Bool {
		try keychain.contains(key.rawValue.rawValue, withoutAuthenticationUI: !showAuthPrompt)
	}

	func getAllKeysMatching(
		synchronizable needleIsSynchronizable: Bool? = false,
		accessibility needleAccessibility: KeychainAccess.Accessibility? = .whenPasscodeSetThisDeviceOnly
	) -> [String] {
		keychain.allItems()
			.filter {
				if let isSynchronizable = $0["synchronizable"] as? Bool, let needle = needleIsSynchronizable {
					isSynchronizable == needle
				} else {
					true
				}
			}
			.filter({
				if let accessibilityRawValue = $0["accessibility"] as? String, let accessibility = KeychainAccess.Accessibility(rawValue: accessibilityRawValue), let needle = needleAccessibility {
					accessibility == needle
				} else {
					true
				}
			}
			).compactMap { $0["key"] as? String }
	}
}

extension KeychainHolder {
	func setDataWithoutAuth(
		_ data: Data,
		forKey key: Key,
		attributes: KeychainClient.AttributesWithoutAuth
	) throws {
		try withAttributes(of: attributes)
			.set(data, key: key.rawValue.rawValue)
		keychainChangedSubject.send(())
	}

	func setDataWithAuth(
		_ data: Data,
		forKey key: Key,
		attributes: KeychainClient.AttributesWithAuth
	) throws {
		try withAttributes(of: attributes)
			.set(data, key: key.rawValue.rawValue)
		keychainChangedSubject.send(())
	}

	func getDataWithoutAuth(
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

	func getDataWithAuth(
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

	func getDataWithoutAuth(
		forKey key: Key
	) throws -> Data? {
		try keychain.getData(key.rawValue.rawValue)
	}

	func getDataWithAuth(
		forKey key: Key,
		authenticationPrompt: AuthenticationPrompt
	) throws -> Data? {
		try keychain
			.authenticationPrompt(authenticationPrompt.rawValue.rawValue)
			.getData(key.rawValue.rawValue)
	}

	func removeData(
		forKey key: Key
	) throws {
		try keychain.remove(key.rawValue.rawValue)
		keychainChangedSubject.send(())
	}

	func removeAllItems() throws {
		try keychain.removeAll()
		keychainChangedSubject.send(())
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
