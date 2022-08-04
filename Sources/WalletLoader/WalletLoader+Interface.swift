import ComposableArchitecture
import Profile
import Wallet

// MARK: - WalletLoader
public struct WalletLoader {
	public var loadWallet: (Profile) -> Effect<Wallet, Error>
}

public extension WalletLoader {
	enum Error: Swift.Error, Equatable {
		case secretsNoFoundForProfile
	}
}

#if DEBUG
public extension WalletLoader {
	static let noop = Self(
		loadWallet: { _ in .none }
	)
}
#endif // DEBUG
