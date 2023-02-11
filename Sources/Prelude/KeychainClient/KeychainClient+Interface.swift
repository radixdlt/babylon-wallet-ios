import Foundation
@preconcurrency import KeychainAccess

// MARK: - KeychainClient
public struct KeychainClient: Sendable {
	public typealias Key = String

	public var dataForKey: DataForKey
	public var removeDataForKey: RemoveDataForKey

	/// Saves items in Keychain using access option `kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly`
	/// read more: https://developer.apple.com/documentation/security/ksecattraccessiblewhenpasscodesetthisdeviceonly
	public var setDataForKey: SetDataForKey

	public var updateDataForKey: UpdateDataForKey

	init(
		dataForKey: @escaping DataForKey,
		removeDataForKey: @escaping RemoveDataForKey,
		setDataForKey: @escaping SetDataForKey,
		updateDataForKey: @escaping UpdateDataForKey
	) {
		self.dataForKey = dataForKey
		self.removeDataForKey = removeDataForKey
		self.setDataForKey = setDataForKey
		self.updateDataForKey = updateDataForKey
	}
}

extension KeychainClient {
	public typealias DataForKey = @Sendable (Key, AuthenticationPrompt) async throws -> Data?
	public typealias RemoveDataForKey = @Sendable (Key) async throws -> Void
	/// Use `Protection` if you want to override default `accessibility` and `authenticationPolicy` configs
	public typealias SetDataForKey = @Sendable (Data, Key, Protection?) async throws -> Void
	public typealias UpdateDataForKey = @Sendable (Data, Key, Protection?, AuthenticationPrompt?) async throws -> Void

	public struct Protection: Sendable {
		public let accessibility: KeychainAccess.Accessibility
		public let authenticationPolicy: AuthenticationPolicy

		public init(accessibility: KeychainAccess.Accessibility, authenticationPolicy: AuthenticationPolicy) {
			self.accessibility = accessibility
			self.authenticationPolicy = authenticationPolicy
		}

		public static let defaultForProfile = Self(accessibility: .whenPasscodeSetThisDeviceOnly, authenticationPolicy: [])
	}
}

public typealias AuthenticationPrompt = String
