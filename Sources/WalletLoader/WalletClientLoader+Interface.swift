import ComposableArchitecture
import ProfileLoader
import Profile
import WalletClient
import XCTestDynamicOverlay

// MARK: - WalletClientLoader
public struct WalletClientLoader {
	public var loadWalletClient: @Sendable () async throws -> WalletClient
}

#if DEBUG
public extension WalletClientLoader {
	static let unimplemented = Self(
        loadWalletClient: XCTUnimplemented("\(Self.self).loadWalletClient")
	)
}
#endif
