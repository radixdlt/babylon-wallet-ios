import Foundation
@preconcurrency import KeychainAccess
import Tagged

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
		removeAllItems: @escaping RemoveAllItems
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
	}
}

extension KeychainClient {
	public typealias IfNilSetWithoutAuth = IfNilSetWithAttributes<KeychainClient.AttributesWithoutAuth>
	public typealias IfNilSetWithAuth = IfNilSetWithAttributes<KeychainClient.AttributesWithAuth>
	public struct IfNilSetWithAttributes<Attributes: KeychainAttributes & Hashable>: Sendable, Hashable {
		public let value: Data
		public let attributes: Attributes
		public init(to value: Data, with attributes: Attributes) {
			self.value = value
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
	public typealias ContainsDataForKey = @Sendable (Key, _ showAuthPrompt: Bool) async throws -> Bool
	public typealias SetDataWithoutAuthForKey = @Sendable (Data, Key, AttributesWithoutAuth) async throws -> Void
	public typealias GetDataWithoutAuthForKeySetIfNil = @Sendable (Key, IfNilSetWithoutAuth) async throws -> (value: Data, wasNil: Bool)
	public typealias GetDataWithAuthForKeySetIfNil = @Sendable (Key, AuthenticationPrompt, IfNilSetWithAuth) async throws -> (value: Data, wasNil: Bool)
	public typealias SetDataWithAuthForKey = @Sendable (Data, Key, AttributesWithAuth) async throws -> Void

	public typealias GetDataWithoutAuthForKey = @Sendable (Key) async throws -> Data?
	public typealias GetDataWithAuthForKey = @Sendable (Key, AuthenticationPrompt) async throws -> Data?

	public typealias RemoveDataForKey = @Sendable (Key) async throws -> Void
	public typealias RemoveAllItems = @Sendable () async throws -> Void
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
	public func serviceAndAccessGroup() -> KeychainServiceAndAccessGroup {
		_getServiceAndAccessGroup()
	}

	/// Checks if keychain contains an item without prompting showing Auth Prompt
	/// even for items that require auth (if you dont explictily set `showAuthPrompt: true`)
	public func contains(
		_ key: Key,
		showAuthPrompt: Bool = false
	) async throws -> Bool {
		try await _containsDataForKey(key, showAuthPrompt)
	}

	public func setDataWithoutAuth(
		_ data: Data,
		forKey key: Key,
		attributes: KeychainClient.AttributesWithoutAuth
	) async throws {
		try await _setDataWithoutAuthForKey(data, key, attributes)
	}

	public func setDataWithAuth(
		_ data: Data,
		forKey key: Key,
		attributes: KeychainClient.AttributesWithAuth
	) async throws {
		try await _setDataWithAuthForKey(data, key, attributes)
	}

	public func getDataWithoutAuthForKeySetIfNil(
		forKey key: Key,
		ifNilSet: KeychainClient.IfNilSetWithoutAuth
	) async throws -> (value: Data, wasNil: Bool) {
		try await _getDataWithoutAuthForKeySetIfNil(key, ifNilSet)
	}

	public func getDataWithAuthForKeySetIfNil(
		forKey key: Key,
		authenticationPrompt: AuthenticationPrompt,
		ifNilSet: KeychainClient.IfNilSetWithAuth
	) async throws -> (value: Data, wasNil: Bool) {
		try await _getDataWithAuthForKeySetIfNil(key, authenticationPrompt, ifNilSet)
	}

	public func getDataWithoutAuth(
		forKey key: Key
	) async throws -> Data? {
		try await _getDataWithoutAuthForKey(key)
	}

	public func getDataWithAuth(
		forKey key: Key,
		authenticationPrompt: AuthenticationPrompt
	) async throws -> Data? {
		try await _getDataWithAuthForKey(key, authenticationPrompt)
	}

	public func removeData(
		forKey key: Key
	) async throws {
		try await _removeDataForKey(key)
	}

	public func removeAllItems() async throws {
		try await _removeAllItems()
	}
}
