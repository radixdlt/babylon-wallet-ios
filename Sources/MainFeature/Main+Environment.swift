import Common
import ComposableArchitecture
import Foundation
import UserDefaultsClient
import Wallet

public extension Main {
	// MARK: Environment
	struct Environment {
		public let userDefaultsClient: UserDefaultsClient
		public let wallet: Wallet

		public init(
			userDefaultsClient: UserDefaultsClient,
			wallet: Wallet
		) {
			self.userDefaultsClient = userDefaultsClient
			self.wallet = wallet
		}
	}
}

#if DEBUG
public extension Main.Environment {
	static let noop = Self(
		userDefaultsClient: .noop,
		wallet: .noop
	)
}
#endif // DEBUG
