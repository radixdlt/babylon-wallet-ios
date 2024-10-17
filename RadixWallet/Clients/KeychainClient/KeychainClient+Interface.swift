import Foundation
@preconcurrency import KeychainAccess

// MARK: - KeychainClient
/// A CRUD client around Keychain, that provides async methods for operations that requires auth
/// and sync methods for operations on data without authentication.
struct KeychainClient: Sendable {
	var _getServiceAndAccessGroup: GetServiceAndAccessGroup
	var _containsDataForKey: ContainsDataForKey
	var _setDataWithoutAuthForKey: SetDataWithoutAuthForKey
	var _setDataWithAuthForKey: SetDataWithAuthForKey
	var _getDataWithoutAuthForKeySetIfNil: GetDataWithoutAuthForKeySetIfNil
	var _getDataWithAuthForKeySetIfNil: GetDataWithAuthForKeySetIfNil
	var _getDataWithoutAuthForKey: GetDataWithoutAuthForKey
	var _getDataWithAuthForKey: GetDataWithAuthForKey
	var _removeDataForKey: RemoveDataForKey
	var _removeAllItems: RemoveAllItems
	var _getAllKeysMatchingAttributes: GetAllKeysMatchingAttributes

	/// This a _best effort_ publisher that will emit a change every time the Keychain is changed due to actions inside the Wallet app.
	/// However, we cannot detect external changes (e.g. Keychain getting wiped when passcode is deleted).
	var _keychainChanged: KeychainChanged

	init(
		getServiceAndAccessGroup: @escaping GetServiceAndAccessGroup,
		containsDataForKey: @escaping ContainsDataForKey,
		setDataWithoutAuthForKey: @escaping SetDataWithoutAuthForKey,
		setDataWithAuthForKey: @escaping SetDataWithAuthForKey,
		getDataWithoutAuthForKeySetIfNil: @escaping GetDataWithoutAuthForKeySetIfNil,
		getDataWithAuthForKeySetIfNil: @escaping GetDataWithAuthForKeySetIfNil,
		getDataWithoutAuthForKey: @escaping GetDataWithoutAuthForKey,
		getDataWithAuthForKey: @escaping GetDataWithAuthForKey,
		removeDataForKey: @escaping RemoveDataForKey,
		removeAllItems: @escaping RemoveAllItems,
		getAllKeysMatchingAttributes: @escaping GetAllKeysMatchingAttributes,
		keychainChanged: @escaping KeychainChanged
	) {
		self._getServiceAndAccessGroup = getServiceAndAccessGroup
		self._containsDataForKey = containsDataForKey
		self._setDataWithoutAuthForKey = setDataWithoutAuthForKey
		self._setDataWithAuthForKey = setDataWithAuthForKey
		self._getDataWithoutAuthForKeySetIfNil = getDataWithoutAuthForKeySetIfNil
		self._getDataWithAuthForKeySetIfNil = getDataWithAuthForKeySetIfNil
		self._getDataWithoutAuthForKey = getDataWithoutAuthForKey
		self._getDataWithAuthForKey = getDataWithAuthForKey
		self._removeDataForKey = removeDataForKey
		self._removeAllItems = removeAllItems
		self._getAllKeysMatchingAttributes = getAllKeysMatchingAttributes
		self._keychainChanged = keychainChanged
	}
}

extension KeychainClient {
	typealias IfNilSetWithoutAuth = IfNilSetWithAttributes<KeychainClient.AttributesWithoutAuth>
	typealias IfNilSetWithAuth = IfNilSetWithAttributes<KeychainClient.AttributesWithAuth>

	struct IfNilSetWithAttributes<Attributes: KeychainAttributes>: Sendable {
		typealias GetValueToSet = @Sendable () throws -> Data

		let getValueToSet: GetValueToSet
		let attributes: Attributes

		init(to getValueToSet: @escaping @autoclosure GetValueToSet, with attributes: Attributes) {
			self.getValueToSet = getValueToSet
			self.attributes = attributes
		}
	}

	struct KeychainServiceAndAccessGroup: Sendable, Hashable {
		let service: String
		let accessGroup: String?
	}

	typealias Label = Tagged<Self, NonEmptyString>
	typealias Comment = Tagged<Self, NonEmptyString>
	typealias Key = Tagged<Self, NonEmptyString>
	typealias AuthenticationPrompt = Tagged<Self, NonEmptyString>

	typealias GetServiceAndAccessGroup = @Sendable () -> KeychainServiceAndAccessGroup
	typealias ContainsDataForKey = @Sendable (Key, _ showAuthPrompt: Bool) throws -> Bool
	typealias SetDataWithoutAuthForKey = @Sendable (Data, Key, AttributesWithoutAuth) throws -> Void
	typealias GetDataWithoutAuthForKeySetIfNil = @Sendable (Key, IfNilSetWithoutAuth) throws -> (value: Data, wasNil: Bool)
	typealias GetDataWithAuthForKeySetIfNil = @Sendable (Key, AuthenticationPrompt, IfNilSetWithAuth) throws -> (value: Data, wasNil: Bool)
	typealias SetDataWithAuthForKey = @Sendable (Data, Key, AttributesWithAuth) throws -> Void

	typealias GetDataWithoutAuthForKey = @Sendable (Key) throws -> Data?
	typealias GetDataWithAuthForKey = @Sendable (Key, AuthenticationPrompt) throws -> Data?

	typealias RemoveDataForKey = @Sendable (Key) throws -> Void
	typealias RemoveAllItems = @Sendable () throws -> Void
	typealias GetAllKeysMatchingAttributes = @Sendable (
		(synchronizable: Bool?,
		 accessibility: KeychainAccess.Accessibility?)
	) -> [Key]

	typealias KeychainChanged = @Sendable () -> AnyAsyncSequence<Void>
}

// MARK: - KeychainAttributes
protocol KeychainAttributes: Sendable {
	var iCloudSyncEnabled: Bool { get }
	var accessibility: KeychainAccess.Accessibility { get }
	var label: KeychainClient.Label? { get }
	var comment: KeychainClient.Comment? { get }
}

extension KeychainClient {
	struct AttributesWithAuth: KeychainAttributes, Hashable {
		let iCloudSyncEnabled: Bool
		let accessibility: KeychainAccess.Accessibility
		let label: KeychainClient.Label?
		let comment: KeychainClient.Comment?
		let authenticationPolicy: KeychainAccess.AuthenticationPolicy?

		init(
			iCloudSyncEnabled: Bool = false,
			accessibility: KeychainAccess.Accessibility,
			authenticationPolicy: KeychainAccess.AuthenticationPolicy? = nil,
			label: Label? = nil,
			comment: Comment? = nil
		) {
			self.iCloudSyncEnabled = iCloudSyncEnabled
			self.accessibility = accessibility
			self.authenticationPolicy = authenticationPolicy
			self.label = label
			self.comment = comment
		}
	}

	struct AttributesWithoutAuth: KeychainAttributes, Hashable {
		let iCloudSyncEnabled: Bool
		let accessibility: KeychainAccess.Accessibility
		let label: KeychainClient.Label?
		let comment: KeychainClient.Comment?

		init(
			iCloudSyncEnabled: Bool = false,
			accessibility: KeychainAccess.Accessibility,
			label: Label? = nil,
			comment: Comment? = nil
		) {
			self.iCloudSyncEnabled = iCloudSyncEnabled
			self.accessibility = accessibility
			self.label = label
			self.comment = comment
		}
	}
}

extension KeychainClient {
	func keychainChanged() -> AnyAsyncSequence<Void> {
		_keychainChanged()
	}

	func serviceAndAccessGroup() -> KeychainServiceAndAccessGroup {
		_getServiceAndAccessGroup()
	}

	/// Checks if keychain contains an item without prompting showing Auth Prompt
	/// even for items that require auth (if you dont explictily set `showAuthPrompt: true`)
	func contains(
		_ key: Key,
		showAuthPrompt: Bool = false
	) throws -> Bool {
		try _containsDataForKey(key, showAuthPrompt)
	}

	func setDataWithoutAuth(
		_ data: Data,
		forKey key: Key,
		attributes: KeychainClient.AttributesWithoutAuth
	) throws {
		try _setDataWithoutAuthForKey(data, key, attributes)
	}

	func setDataWithAuth(
		_ data: Data,
		forKey key: Key,
		attributes: KeychainClient.AttributesWithAuth
	) throws {
		try _setDataWithAuthForKey(data, key, attributes)
	}

	func getDataWithoutAuth(
		forKey key: Key,
		ifNilSet: KeychainClient.IfNilSetWithoutAuth
	) throws -> (value: Data, wasNil: Bool) {
		try _getDataWithoutAuthForKeySetIfNil(key, ifNilSet)
	}

	func getDataWithAuth(
		forKey key: Key,
		authenticationPrompt: AuthenticationPrompt,
		ifNilSet: KeychainClient.IfNilSetWithAuth
	) throws -> (value: Data, wasNil: Bool) {
		try _getDataWithAuthForKeySetIfNil(key, authenticationPrompt, ifNilSet)
	}

	func getDataWithoutAuth(
		forKey key: Key
	) throws -> Data? {
		try _getDataWithoutAuthForKey(key)
	}

	func getDataWithAuth(
		forKey key: Key,
		authenticationPrompt: AuthenticationPrompt
	) throws -> Data? {
		try _getDataWithAuthForKey(key, authenticationPrompt)
	}

	func removeData(
		forKey key: Key
	) throws {
		try _removeDataForKey(key)
	}

	func removeAllItems() throws {
		try _removeAllItems()
	}

	func getAllKeysMatchingAttributes(
		synchronizable: Bool? = false,
		accessibility: KeychainAccess.Accessibility? = .whenPasscodeSetThisDeviceOnly
	) -> [Key] {
		_getAllKeysMatchingAttributes((synchronizable, accessibility))
	}
}
