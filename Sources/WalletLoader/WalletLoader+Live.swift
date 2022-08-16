import Combine
import ComposableArchitecture
import Foundation
import Wallet

public extension WalletLoader {
	static let live = Self(
		/*
		 loadWallet: { profile in
		 	Just(Wallet(profile: profile))
		 		.setFailureType(to: Error.self)
		 		.eraseToEffect()
		 }
		 */
		loadWallet: { _ in
			.none
		}
	)
}
