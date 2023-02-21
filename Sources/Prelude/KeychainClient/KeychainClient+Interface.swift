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

	public typealias AddDataWithoutAuthForKey = @Sendable (AddItemWithoutAuthRequest) throws -> Void
	public typealias AddDataWithAuthForKey = @Sendable (AddItemWithAuthRequest) async throws -> Void

	public typealias GetDataWithoutAuthForKey = @Sendable (Key) throws -> Data?
	public typealias GetDataWithAuthForKey = @Sendable (Key, AuthenticationPrompt) async throws -> Data?

	public typealias UpdateDataWithoutAuthForKey = @Sendable (Data, Key) throws -> Void
	public typealias UpdateDataWithAuthForKey = @Sendable (Data, Key, AuthenticationPrompt) async throws -> Void

	public typealias RemoveDataForKey = @Sendable (Key) throws -> Void
	public typealias RemoveAllItems = @Sendable () throws -> Void
}

// MARK: - AddKeychainItemWithRequest
public protocol AddKeychainItemWithRequest {
	var data: Data { get }
	var key: KeychainClient.Key { get }
	var accessibility: KeychainAccess.Accessibility { get }
	var comment: KeychainClient.Comment? { get }
	var label: KeychainClient.Label? { get }
}

extension KeychainClient {
	public struct AddItemWithAuthRequest: Sendable, Equatable, AddKeychainItemWithRequest {
		public let data: Data
		public let key: Key
		public let accessibility: KeychainAccess.Accessibility
		public let authenticationPolicy: AuthenticationPolicy
		public let comment: Comment?
		public let label: Label?

		public init(
			data: Data,
			key: Key,
			accessibility: KeychainAccess.Accessibility,
			authenticationPolicy: AuthenticationPolicy,
			comment: Comment?,
			label: Label?
		) {
			self.data = data
			self.key = key
			self.accessibility = accessibility
			self.authenticationPolicy = authenticationPolicy
			self.comment = comment
			self.label = label
		}
	}

	public struct AddItemWithoutAuthRequest: Sendable, Equatable, AddKeychainItemWithRequest {
		public let data: Data
		public let key: Key
		public let accessibility: KeychainAccess.Accessibility
		public let comment: Comment?
		public let label: Label?

		public init(
			data: Data,
			key: Key,
			accessibility: KeychainAccess.Accessibility,
			comment: Comment?,
			label: Label?
		) {
			self.data = data
			self.key = key
			self.accessibility = accessibility
			self.comment = comment
			self.label = label
		}
	}
}
