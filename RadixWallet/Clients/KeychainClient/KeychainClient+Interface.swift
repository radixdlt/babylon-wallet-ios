import Foundation
@preconcurrency import KeychainAccess

// MARK: - KeychainClient
/// A CRUD client around Keychain, that provides async methods for operations that requires auth
/// and sync methods for operations on data without authentication.
public struct KeychainClient: Sendable {
	public var _getServiceAndAccessGroup: GetServiceAndAccessGroup
	public var _containsDataForKey: ContainsDataForKey
	public var _setDataWithoutAuthForKey: SetDataWithoutAuthForKey
	public var _setDataWithAuthForKey: SetDataWithAuthForKey
	public var _getDataWithoutAuthForKeySetIfNil: GetDataWithoutAuthForKeySetIfNil
	public var _getDataWithAuthForKeySetIfNil: GetDataWithAuthForKeySetIfNil
	public var _getDataWithoutAuthForKey: GetDataWithoutAuthForKey
	public var _getDataWithAuthForKey: GetDataWithAuthForKey
	public var _removeDataForKey: RemoveDataForKey
	public var _removeAllItems: RemoveAllItems
	public var _getAllKeysMatchingAttributes: GetAllKeysMatchingAttributes

	/// This a _best effort_ publisher that will emit a change every time the Keychain is changed due to actions inside the Wallet app.
	/// However, we cannot detect external changes (e.g. Keychain getting wiped when passcode is deleted).
	public var _keychainChanged: KeychainChanged

	public init(
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
	public typealias IfNilSetWithoutAuth = IfNilSetWithAttributes<KeychainClient.AttributesWithoutAuth>
	public typealias IfNilSetWithAuth = IfNilSetWithAttributes<KeychainClient.AttributesWithAuth>

	public struct IfNilSetWithAttributes<Attributes: KeychainAttributes>: Sendable {
		public typealias GetValueToSet = @Sendable () throws -> Data

		public let getValueToSet: GetValueToSet
		public let attributes: Attributes

		public init(to getValueToSet: @escaping @autoclosure GetValueToSet, with attributes: Attributes) {
			self.getValueToSet = getValueToSet
			self.attributes = attributes
		}
	}

	public struct KeychainServiceAndAccessGroup: Sendable, Hashable {
		public let service: String
		public let accessGroup: String?
	}

	public typealias Label = Tagged<Self, NonEmptyString>
	public typealias Comment = Tagged<Self, NonEmptyString>
	public typealias Key = Tagged<Self, NonEmptyString>
	public typealias AuthenticationPrompt = Tagged<Self, NonEmptyString>

	public typealias GetServiceAndAccessGroup = @Sendable () -> KeychainServiceAndAccessGroup
	public typealias ContainsDataForKey = @Sendable (Key, _ showAuthPrompt: Bool) throws -> Bool
	public typealias SetDataWithoutAuthForKey = @Sendable (Data, Key, AttributesWithoutAuth) throws -> Void
	public typealias GetDataWithoutAuthForKeySetIfNil = @Sendable (Key, IfNilSetWithoutAuth) throws -> (value: Data, wasNil: Bool)
	public typealias GetDataWithAuthForKeySetIfNil = @Sendable (Key, AuthenticationPrompt, IfNilSetWithAuth) throws -> (value: Data, wasNil: Bool)
	public typealias SetDataWithAuthForKey = @Sendable (Data, Key, AttributesWithAuth) throws -> Void

	public typealias GetDataWithoutAuthForKey = @Sendable (Key) throws -> Data?
	public typealias GetDataWithAuthForKey = @Sendable (Key, AuthenticationPrompt) throws -> Data?

	public typealias RemoveDataForKey = @Sendable (Key) throws -> Void
	public typealias RemoveAllItems = @Sendable () throws -> Void
	public typealias GetAllKeysMatchingAttributes = @Sendable (
		(synchronizable: Bool?,
		 accessibility: KeychainAccess.Accessibility?)
	) -> [Key]

	public typealias KeychainChanged = @Sendable () -> AnyAsyncSequence<Void>
}

// MARK: - KeychainAttributes
public protocol KeychainAttributes: Sendable {
	var iCloudSyncEnabled: Bool { get }
	var accessibility: KeychainAccess.Accessibility { get }
	var label: KeychainClient.Label? { get }
	var comment: KeychainClient.Comment? { get }
}

extension KeychainClient {
	public struct AttributesWithAuth: KeychainAttributes, Hashable {
		public let iCloudSyncEnabled: Bool
		public let accessibility: KeychainAccess.Accessibility
		public let label: KeychainClient.Label?
		public let comment: KeychainClient.Comment?
		public let authenticationPolicy: KeychainAccess.AuthenticationPolicy?

		public init(
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

	public struct AttributesWithoutAuth: KeychainAttributes, Hashable {
		public let iCloudSyncEnabled: Bool
		public let accessibility: KeychainAccess.Accessibility
		public let label: KeychainClient.Label?
		public let comment: KeychainClient.Comment?

		public init(
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
	public func keychainChanged() -> AnyAsyncSequence<Void> {
		_keychainChanged()
	}

	public func serviceAndAccessGroup() -> KeychainServiceAndAccessGroup {
		_getServiceAndAccessGroup()
	}

	/// Checks if keychain contains an item without prompting showing Auth Prompt
	/// even for items that require auth (if you dont explictily set `showAuthPrompt: true`)
	public func contains(
		_ key: Key,
		showAuthPrompt: Bool = false
	) throws -> Bool {
		try _containsDataForKey(key, showAuthPrompt)
	}

	public func setDataWithoutAuth(
		_ data: Data,
		forKey key: Key,
		attributes: KeychainClient.AttributesWithoutAuth
	) throws {
		try _setDataWithoutAuthForKey(data, key, attributes)
	}

	public func setDataWithAuth(
		_ data: Data,
		forKey key: Key,
		attributes: KeychainClient.AttributesWithAuth
	) throws {
		try _setDataWithAuthForKey(data, key, attributes)
	}

	public func getDataWithoutAuth(
		forKey key: Key,
		ifNilSet: KeychainClient.IfNilSetWithoutAuth
	) throws -> (value: Data, wasNil: Bool) {
		try _getDataWithoutAuthForKeySetIfNil(key, ifNilSet)
	}

	public func getDataWithAuth(
		forKey key: Key,
		authenticationPrompt: AuthenticationPrompt,
		ifNilSet: KeychainClient.IfNilSetWithAuth
	) throws -> (value: Data, wasNil: Bool) {
		try _getDataWithAuthForKeySetIfNil(key, authenticationPrompt, ifNilSet)
	}

	public func getDataWithoutAuth(
		forKey key: Key
	) throws -> Data? {
		try _getDataWithoutAuthForKey(key)
	}

	public func getDataWithAuth(
		forKey key: Key,
		authenticationPrompt: AuthenticationPrompt
	) throws -> Data? {
		try _getDataWithAuthForKey(key, authenticationPrompt)
	}

	public func removeData(
		forKey key: Key
	) throws {
		try _removeDataForKey(key)
	}

	public func removeAllItems() throws {
		try _removeAllItems()
	}

	public func getAllKeysMatchingAttributes(
		synchronizable: Bool? = false,
		accessibility: KeychainAccess.Accessibility? = .whenPasscodeSetThisDeviceOnly
	) -> [Key] {
		_getAllKeysMatchingAttributes((synchronizable, accessibility))
	}
}
