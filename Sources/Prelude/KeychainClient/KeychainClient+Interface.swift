import Foundation
@preconcurrency import KeychainAccess
import Tagged

// MARK: - KeychainClient
/// A CRUD client around Keychain, that provides async methods for operations that requires auth
/// and sync methods for operations on data without authentication.
public struct KeychainClient: Sendable {
	/// `sync` adds data for `key` protected with specified accessibility, if a `Label` is provided it
	/// will be set. If a `Comment` is provided, it will be set.
	public var addDataWithoutAuthForKey: AddDataWithoutAuthForKey

	/// `async` adds data for `key` protected with specified accessibility and authentication policy.
	/// If a `Label` is provided it will be set. If a `Comment` is provided, it will be set.
	public var addDataWithAuthForKey: AddDataWithAuthForKey

	/// `sync` reads data for `key`.
	public var getDataWithoutAuthForKey: GetDataWithoutAuthForKey

	/// `async` reads data for `key` and prompts user with `AuthenticationPrompt` when doing so.
	public var getDataWithAuthForKey: GetDataWithAuthForKey

	/// `sync` updates `data` for `key`.
	public var updateDataWithoutAuthForKey: UpdateDataWithoutAuthForKey

	/// `async` updates `data` by `key` and prompts user with `AuthenticationPrompt` when doing so.
	public var updateDataWithAuthForKey: UpdateDataWithAuthForKey

	/// There is no way to show auth when removing Keychain item
	public var removeDataForKey: RemoveDataForKey

	/// removes all items
	public var removeAllItems: RemoveAllItems
}

extension KeychainClient {
	public typealias Label = Tagged<Self, NonEmptyString>
	public typealias Comment = Tagged<Self, NonEmptyString>
	public typealias Key = Tagged<Self, NonEmptyString>
	public typealias AuthenticationPrompt = Tagged<Self, NonEmptyString>

	public typealias AddDataWithoutAuthForKey = @Sendable (AddItemWithoutAuthRequest) async throws -> Void
	public typealias AddDataWithAuthForKey = @Sendable (AddItemWithAuthRequest) async throws -> Void

	public typealias GetDataWithoutAuthForKey = @Sendable (Key) async throws -> Data?
	public typealias GetDataWithAuthForKey = @Sendable (Key, AuthenticationPrompt) async throws -> Data?

	public typealias UpdateDataWithoutAuthForKey = @Sendable (Data, Key) async throws -> Void
	public typealias UpdateDataWithAuthForKey = @Sendable (Data, Key, AuthenticationPrompt) async throws -> Void

	public typealias RemoveDataForKey = @Sendable (Key) async throws -> Void
	public typealias RemoveAllItems = @Sendable () async throws -> Void
}

// MARK: - AddKeychainItemWithRequest
public protocol AddKeychainItemWithRequest {
	var data: Data { get }
	var iCloudSyncEnabled: Bool { get }
	var key: KeychainClient.Key { get }
	var accessibility: KeychainAccess.Accessibility { get }
	var label: KeychainClient.Label? { get }
	var comment: KeychainClient.Comment? { get }
}

extension KeychainClient {
	public func addDataWithAuthenticationPolicyIfAble(
		data: Data,
		key: Key,
		iCloudSyncEnabled: Bool,
		accessibility: KeychainAccess.Accessibility,
		authenticationPolicy: AuthenticationPolicy?,
		label: Label?,
		comment: Comment?
	) async throws {
		if let authenticationPolicy {
			try await self.addDataWithAuthForKey(.init(
				data: data,
				key: key,
				iCloudSyncEnabled: iCloudSyncEnabled,
				accessibility: accessibility,
				authenticationPolicy: authenticationPolicy,
				label: label,
				comment: comment
			))
		} else {
			try await self.addDataWithoutAuthForKey(.init(
				data: data,
				key: key,
				iCloudSyncEnabled: iCloudSyncEnabled,
				accessibility: accessibility,
				label: label,
				comment: comment
			))
		}
	}
}

extension KeychainClient {
	public struct AddItemWithAuthRequest: Sendable, Equatable, AddKeychainItemWithRequest {
		public let data: Data
		public let key: Key
		public let iCloudSyncEnabled: Bool
		public let accessibility: KeychainAccess.Accessibility
		public let authenticationPolicy: AuthenticationPolicy
		public let comment: Comment?
		public let label: Label?

		public init(
			data: Data,
			key: Key,
			iCloudSyncEnabled: Bool,
			accessibility: KeychainAccess.Accessibility,
			authenticationPolicy: AuthenticationPolicy,
			label: Label?,
			comment: Comment?
		) {
			self.data = data
			self.key = key
			self.iCloudSyncEnabled = iCloudSyncEnabled
			self.accessibility = accessibility
			self.authenticationPolicy = authenticationPolicy
			self.label = label
			self.comment = comment
		}
	}

	public struct AddItemWithoutAuthRequest: Sendable, Equatable, AddKeychainItemWithRequest {
		public let data: Data
		public let key: Key
		public let iCloudSyncEnabled: Bool
		public let accessibility: KeychainAccess.Accessibility
		public let label: Label?
		public let comment: Comment?

		public init(
			data: Data,
			key: Key,
			iCloudSyncEnabled: Bool,
			accessibility: KeychainAccess.Accessibility,
			label: Label?,
			comment: Comment?
		) {
			self.data = data
			self.key = key
			self.iCloudSyncEnabled = iCloudSyncEnabled
			self.accessibility = accessibility
			self.label = label
			self.comment = comment
		}
	}
}
