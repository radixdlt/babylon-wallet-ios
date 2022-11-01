import AccountPortfolio
import AppSettings
import KeychainClient
import PasteboardClient
import ProfileClient

// MARK: - Main.Environment
public extension Main {
	// MARK: Environment
	struct Environment {
		public let accountPortfolioFetcher: AccountPortfolioFetcher
		public let appSettingsClient: AppSettingsClient
		public let keychainClient: KeychainClient
		public let pasteboardClient: PasteboardClient
		public let profileClient: ProfileClient

		public init(
			accountPortfolioFetcher: AccountPortfolioFetcher,
			appSettingsClient: AppSettingsClient,
			keychainClient: KeychainClient,
			pasteboardClient: PasteboardClient,
			profileClient: ProfileClient
		) {
			self.accountPortfolioFetcher = accountPortfolioFetcher
			self.appSettingsClient = appSettingsClient
			self.keychainClient = keychainClient
			self.pasteboardClient = pasteboardClient
			self.profileClient = profileClient
		}
	}
}

#if DEBUG
public extension Main.Environment {
	static let noop = Self(
		accountPortfolioFetcher: .noop,
		appSettingsClient: .noop,
		keychainClient: .unimplemented,
		pasteboardClient: .noop,
		profileClient: .unimplemented
	)

	static let unimplemented = Self(
		accountPortfolioFetcher: .testValue,
		appSettingsClient: .testValue,
		keychainClient: .unimplemented,
		pasteboardClient: .testValue,
		profileClient: .unimplemented
	)
}
#endif
