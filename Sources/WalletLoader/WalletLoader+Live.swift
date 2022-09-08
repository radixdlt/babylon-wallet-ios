import Foundation

public extension WalletLoader {
	static let live = Self(
		loadWallet: { _ in
			.placeholder
		}
	)
}
