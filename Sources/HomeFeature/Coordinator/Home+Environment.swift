import AccountDetailsFeature
import AccountPortfolio
import AppSettings
import FungibleTokenListFeature
import PasteboardClient
import WalletClient

// MARK: - Home.Environment
public extension Home {
	// MARK: Environment
	struct Environment {
		public let appSettingsClient: AppSettingsClient
		public let accountPortfolioFetcher: AccountPortfolioFetcher
		public let pasteboardClient: PasteboardClient
		public let fungibleTokenListSorter: FungibleTokenListSorter
		public let walletClient: WalletClient

		public init(
			walletClient: WalletClient,
			appSettingsClient: AppSettingsClient,
			accountPortfolioFetcher: AccountPortfolioFetcher,
			pasteboardClient: PasteboardClient,
			fungibleTokenListSorter: FungibleTokenListSorter = .live
		) {
			self.walletClient = walletClient
			self.appSettingsClient = appSettingsClient
			self.accountPortfolioFetcher = accountPortfolioFetcher
			self.pasteboardClient = pasteboardClient
			self.fungibleTokenListSorter = fungibleTokenListSorter
		}
	}
}

#if DEBUG
public extension Home.Environment {
	static let placeholder: Self = .init(
		walletClient: .mock(),
		appSettingsClient: .mock,
		accountPortfolioFetcher: .mock,
		pasteboardClient: .noop,
		fungibleTokenListSorter: .mock
	)

	static let unimplemented: Self = .init(
		walletClient: .unimplemented,
		appSettingsClient: .unimplemented,
		accountPortfolioFetcher: .unimplemented,
		pasteboardClient: .unimplemented,
		fungibleTokenListSorter: .unimplemented
	)
}
#endif
