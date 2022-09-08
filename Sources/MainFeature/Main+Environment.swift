import AccountWorthFetcher
import AppSettings
import PasteboardClient
import UserDefaultsClient

public extension Main {
	// MARK: Environment
	struct Environment {
		public let accountWorthFetcher: AccountWorthFetcher
		public let appSettingsClient: AppSettingsClient
		public let pasteboardClient: PasteboardClient
		public let userDefaultsClient: UserDefaultsClient

		public init(
			accountWorthFetcher: AccountWorthFetcher,
			appSettingsClient: AppSettingsClient,
			pasteboardClient: PasteboardClient,
			userDefaultsClient: UserDefaultsClient
		) {
			self.accountWorthFetcher = accountWorthFetcher
			self.appSettingsClient = appSettingsClient
			self.pasteboardClient = pasteboardClient
			self.userDefaultsClient = userDefaultsClient
		}
	}
}

#if DEBUG
public extension Main.Environment {
	static let noop = Self(
		accountWorthFetcher: .mock,
		appSettingsClient: .mock,
		pasteboardClient: .noop,
		userDefaultsClient: .noop
	)
}
#endif // DEBUG
