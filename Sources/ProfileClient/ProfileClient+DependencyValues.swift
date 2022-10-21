import ComposableArchitecture
import Foundation

// MARK: - WalletClientKey
public enum WalletClientKey: DependencyKey {}
public extension WalletClientKey {
	typealias Value = ProfileClient
	static let liveValue = ProfileClient.live
	static let testValue = ProfileClient.mock()
}

public extension DependencyValues {
	var profileClient: ProfileClient {
		get { self[WalletClientKey.self] }
		set { self[WalletClientKey.self] = newValue }
	}
}
