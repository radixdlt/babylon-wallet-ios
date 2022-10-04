import AccountDetailsFeature
import AccountPortfolio
import AppSettings
import FungibleTokenListFeature
import PasteboardClient

// MARK: - Home.Environment
public extension Home {
	// MARK: Environment
	struct Environment {
		public let appSettingsClient: AppSettingsClient
		public let accountPortfolioFetcher: AccountPortfolioFetcher
		public let pasteboardClient: PasteboardClient
		public let fungibleTokenListSorter: FungibleTokenListSorter

		public init(
			appSettingsClient: AppSettingsClient,
			accountPortfolioFetcher: AccountPortfolioFetcher,
			pasteboardClient: PasteboardClient,
			fungibleTokenListSorter: FungibleTokenListSorter = .live
		) {
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
		appSettingsClient: .mock,
		accountPortfolioFetcher: .mock,
		pasteboardClient: .noop,
		fungibleTokenListSorter: .mock
	)

	static let unimplemented: Self = .init(
		appSettingsClient: .unimplemented,
		accountPortfolioFetcher: .unimplemented,
		pasteboardClient: .unimplemented,
		fungibleTokenListSorter: .unimplemented
	)
}
#endif
