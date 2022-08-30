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

		public init(
			userDefaultsClient: UserDefaultsClient,
			pasteboardClient: PasteboardClient
		) {
			self.userDefaultsClient = userDefaultsClient
			self.pasteboardClient = pasteboardClient
		}
	}
}

#if DEBUG
public extension Main.Environment {
	static let noop = Self(
		userDefaultsClient: .noop,
		pasteboardClient: .noop
	)
}
#endif // DEBUG
