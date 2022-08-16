import ComposableArchitecture
import Profile
import Wallet

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
		loadWallet: { _ in .noop }
	)
}
#endif
