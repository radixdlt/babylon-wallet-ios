import AccountWorthFetcher
import AppSettings
import PasteboardClient

public extension Home {
	// MARK: Environment
	struct Environment {
		public let appSettingsClient: AppSettingsClient
		public let accountWorthFetcher: AccountWorthFetcher
		public let pasteboardClient: PasteboardClient
		public let assetListSorter: AssetListSorter

		public init(
			appSettingsClient: AppSettingsClient,
			accountWorthFetcher: AccountWorthFetcher,
			pasteboardClient: PasteboardClient,
			assetListSorter: AssetListSorter = .live
		) {
			self.appSettingsClient = appSettingsClient
			self.accountWorthFetcher = accountWorthFetcher
			self.pasteboardClient = pasteboardClient
			self.assetListSorter = assetListSorter
		}
	}
}

#if DEBUG
public extension Home.Environment {
	static let placeholder: Self = .init(
		appSettingsClient: .mock,
		accountWorthFetcher: .mock,
		pasteboardClient: .noop,
		assetListSorter: .mock
	)
}
#endif
