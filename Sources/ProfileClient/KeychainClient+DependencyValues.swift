import ComposableArchitecture
import Foundation
import KeychainAccess
import KeychainClient

public extension KeychainClient {
	static let live = Self.live(
		accessibility: .whenPasscodeSetThisDeviceOnly,
		authenticationPolicy: .biometryCurrentSet
	)
}

// MARK: - KeychainClientKey
private enum KeychainClientKey: DependencyKey {
	typealias Value = KeychainClient
	static let liveValue = KeychainClient.live
	#if DEBUG
	static let testValue = KeychainClient.unimplemented
	#endif // DEBUG
}

public extension DependencyValues {
	var keychainClient: KeychainClient {
		get { self[KeychainClientKey.self] }
		set { self[KeychainClientKey.self] = newValue }
	}
}
