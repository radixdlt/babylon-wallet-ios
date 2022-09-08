import AccountWorthFetcher
import AppSettings
import Common
import ComposableArchitecture
import Foundation
import PasteboardClient
import UserDefaultsClient
import Wallet

public extension Main {
	// MARK: Environment
	struct Environment {
		public let appSettingsClient: AppSettingsClient
		public let accountWorthFetcher: AccountWorthFetcher
		public let userDefaultsClient: UserDefaultsClient
		public let pasteboardClient: PasteboardClient

		public init(
			appSettingsClient: AppSettingsClient,
			accountWorthFetcher: AccountWorthFetcher,
			userDefaultsClient: UserDefaultsClient,
			pasteboardClient: PasteboardClient
		) {
			self.appSettingsClient = appSettingsClient
			self.accountWorthFetcher = accountWorthFetcher
			self.userDefaultsClient = userDefaultsClient
			self.pasteboardClient = pasteboardClient
		}
	}
}

#if DEBUG
public extension Main.Environment {
	static let noop = Self(
		appSettingsClient: .mock,
		accountWorthFetcher: .mock,
		userDefaultsClient: .noop,
		pasteboardClient: .noop
	)
}
#endif // DEBUG
