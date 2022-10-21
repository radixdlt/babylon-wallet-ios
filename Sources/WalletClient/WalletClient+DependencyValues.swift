import ComposableArchitecture
import Foundation

// MARK: - WalletClientKey
public enum WalletClientKey: DependencyKey {}
public extension WalletClientKey {
	typealias Value = WalletClient
	static let liveValue = WalletClient.live
	static let testValue = WalletClient.mock()
}

public extension DependencyValues {
	var walletClient: WalletClient {
		get { self[WalletClientKey.self] }
		set { self[WalletClientKey.self] = newValue }
	}
}
