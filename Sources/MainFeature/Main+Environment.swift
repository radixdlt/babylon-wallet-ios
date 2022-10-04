import AccountPortfolio
import AppSettings
import PasteboardClient
import WalletRemover

// MARK: - Main.Environment
public extension Main {
	// MARK: Environment
	struct Environment {
		public let accountPortfolioFetcher: AccountPortfolioFetcher
		public let appSettingsClient: AppSettingsClient
		public let pasteboardClient: PasteboardClient
		public let walletRemover: WalletRemover

		public init(
			accountPortfolioFetcher: AccountPortfolioFetcher,
			appSettingsClient: AppSettingsClient,
			pasteboardClient: PasteboardClient,
			walletRemover: WalletRemover
		) {
			self.accountPortfolioFetcher = accountPortfolioFetcher
			self.appSettingsClient = appSettingsClient
			self.pasteboardClient = pasteboardClient
			self.walletRemover = walletRemover
		}
	}
}

#if DEBUG
public extension Main.Environment {
	static let noop = Self(
		accountPortfolioFetcher: .mock,
		appSettingsClient: .mock,
		pasteboardClient: .noop,
		walletRemover: .noop
	)

	static let unimplemented = Self(
		accountPortfolioFetcher: .unimplemented,
		appSettingsClient: .unimplemented,
		pasteboardClient: .unimplemented,
		walletRemover: .unimplemented
	)
}
#endif
