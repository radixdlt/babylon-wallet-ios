import Common
import ComposableArchitecture
import Foundation
import PasteboardClient
import UserDefaultsClient
import Wallet

public extension Main {
	// MARK: Environment
	struct Environment {
		public let userDefaultsClient: UserDefaultsClient
		public let pasteboardClient: PasteboardClient
		public let wallet: Wallet

		public init(
			userDefaultsClient: UserDefaultsClient,
			pasteboardClient: PasteboardClient,
			wallet: Wallet
		) {
			self.userDefaultsClient = userDefaultsClient
			self.pasteboardClient = pasteboardClient
			self.wallet = wallet
		}
	}
}

#if DEBUG
public extension Main.Environment {
	static let noop = Self(
		userDefaultsClient: .noop,
		pasteboardClient: .noop,
		wallet: .noop
	)
}
#endif // DEBUG
