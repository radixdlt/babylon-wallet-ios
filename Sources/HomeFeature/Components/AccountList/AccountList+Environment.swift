import Foundation
import Wallet

public extension Home.AccountList {
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
