import ComposableArchitecture
import Foundation
import Wallet

public extension Home {
	// MARK: Environment
	struct Environment {
		public var wallet: Wallet

		public init(
			wallet: Wallet
		) {
			self.wallet = wallet
		}
	}
}

#if DEBUG
public extension Home.Environment {
	static let placeholder = Self(wallet: .placeholder)
}
#endif
