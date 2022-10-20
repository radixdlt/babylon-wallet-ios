import AccountPortfolio
import AppSettings
import KeychainClient
import PasteboardClient
import WalletClient

// MARK: - Main.Environment
public extension Main {
	// MARK: Environment
	struct Environment {
		public let accountPortfolioFetcher: AccountPortfolioFetcher
		public let appSettingsClient: AppSettingsClient
		public let keychainClient: KeychainClient
		public let pasteboardClient: PasteboardClient
		public let walletClient: WalletClient

		public init(
			accountPortfolioFetcher: AccountPortfolioFetcher,
			appSettingsClient: AppSettingsClient,
			keychainClient: KeychainClient,
			pasteboardClient: PasteboardClient,
			walletClient: WalletClient
		) {
			self.accountPortfolioFetcher = accountPortfolioFetcher
			self.appSettingsClient = appSettingsClient
			self.keychainClient = keychainClient
			self.pasteboardClient = pasteboardClient
			self.walletClient = walletClient
		}
	}
}

#if DEBUG
public extension Main.Environment {
	static let noop = Self(
		accountPortfolioFetcher: .mock,
		appSettingsClient: .mock,
		keychainClient: .unimplemented,
		pasteboardClient: .noop,
		walletClient: .unimplemented
	)

	static let unimplemented = Self(
		accountPortfolioFetcher: .unimplemented,
		appSettingsClient: .unimplemented,
		keychainClient: .unimplemented,
		pasteboardClient: .unimplemented,
		walletClient: .unimplemented
	)
}
#endif
