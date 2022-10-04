import AccountWorthFetcher
import AppSettings
import PasteboardClient
import WalletRemover

// MARK: - Main.Environment
public extension Main {
	// MARK: Environment
	struct Environment {
		public let accountWorthFetcher: AccountWorthFetcher
		public let appSettingsClient: AppSettingsClient
		public let pasteboardClient: PasteboardClient
		public let walletRemover: WalletRemover

		public init(
			accountWorthFetcher: AccountWorthFetcher,
			appSettingsClient: AppSettingsClient,
			pasteboardClient: PasteboardClient,
			walletRemover: WalletRemover
		) {
			self.accountWorthFetcher = accountWorthFetcher
			self.appSettingsClient = appSettingsClient
			self.pasteboardClient = pasteboardClient
			self.walletRemover = walletRemover
		}
	}
}

#if DEBUG
public extension Main.Environment {
	static let noop = Self(
		accountWorthFetcher: .mock,
		appSettingsClient: .mock,
		pasteboardClient: .noop,
		walletRemover: .noop
	)

	static let unimplemented = Self(
		accountWorthFetcher: .unimplemented,
		appSettingsClient: .unimplemented,
		pasteboardClient: .unimplemented,
		walletRemover: .unimplemented
	)
}
#endif
