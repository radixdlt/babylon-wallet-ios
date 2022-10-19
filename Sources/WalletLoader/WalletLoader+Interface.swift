import ComposableArchitecture
import ProfileLoader
import Profile
import WalletClient
import XCTestDynamicOverlay

// MARK: - WalletLoader
public struct WalletClientLoader {
	public var loadWallet: @Sendable () async throws -> WalletClient
}

#if DEBUG
public extension WalletClientLoader {
	static let unimplemented = Self(
		loadWallet: XCTUnimplemented("\(Self.self).loadWallet")
	)
}
#endif
