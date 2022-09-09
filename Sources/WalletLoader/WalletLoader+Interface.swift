import ComposableArchitecture
import Profile
import Wallet
import XCTestDynamicOverlay

// MARK: - WalletLoader
public struct WalletLoader {
	public var loadWallet: @Sendable (Profile) async throws -> Wallet
}

public extension WalletLoader {
	enum Error: Swift.Error, Equatable {
		case secretsNoFoundForProfile
	}
}

#if DEBUG
public extension WalletLoader {
	static let noop = Self(
		loadWallet: { _ in .placeholder }
	)

	static let unimplemented = Self(
		loadWallet: XCTUnimplemented("\(Self.self).loadWallet")
	)
}
#endif
