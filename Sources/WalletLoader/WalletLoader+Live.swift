import ComposableArchitecture
import Foundation
import Wallet

public extension WalletLoader {
	static let live = Self(
		loadWallet: { _ in
			.placeholder
		}
	)
}
