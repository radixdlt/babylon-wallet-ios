import AccountWorthFetcher
import AppSettings
import ComposableArchitecture
import PasteboardClient
import ProfileLoader
import UserDefaultsClient
import WalletLoader
import WalletRemover

public extension App {
	// MARK: Environment
	struct Environment {
		public let backgroundQueue: AnySchedulerOf<DispatchQueue>
		public let mainQueue: AnySchedulerOf<DispatchQueue>
		public let appSettingsClient: AppSettingsClient
		public let accountWorthFetcher: AccountWorthFetcher
		public let pasteboardClient: PasteboardClient
		public let profileLoader: ProfileLoader
		public let userDefaultsClient: UserDefaultsClient
		public let walletLoader: WalletLoader
		public let walletRemover: WalletRemover

		public init(
			backgroundQueue: AnySchedulerOf<DispatchQueue>,
			mainQueue: AnySchedulerOf<DispatchQueue>,
			appSettingsClient: AppSettingsClient,
			accountWorthFetcher: AccountWorthFetcher,
			pasteboardClient: PasteboardClient,
			profileLoader: ProfileLoader,
			userDefaultsClient: UserDefaultsClient,
			walletLoader: WalletLoader,
			walletRemover: WalletRemover
		) {
			self.backgroundQueue = backgroundQueue
			self.mainQueue = mainQueue
			self.appSettingsClient = appSettingsClient
			self.accountWorthFetcher = accountWorthFetcher
			self.pasteboardClient = pasteboardClient
			self.profileLoader = profileLoader
			self.userDefaultsClient = userDefaultsClient
			self.walletLoader = walletLoader
			self.walletRemover = walletRemover
		}
	}
}

#if DEBUG
public extension App.Environment {
	static let noop = Self(
		backgroundQueue: .immediate,
		mainQueue: .immediate,
		appSettingsClient: .mock,
		accountWorthFetcher: .mock,
		pasteboardClient: .noop,
		profileLoader: .noop,
		userDefaultsClient: .noop,
		walletLoader: .noop,
		walletRemover: .noop
	)

	static let unimplemented = Self(
		backgroundQueue: .unimplemented,
		mainQueue: .unimplemented,
		appSettingsClient: .unimplemented,
		accountWorthFetcher: .unimplemented,
		pasteboardClient: .unimplemented,
		profileLoader: .unimplemented,
		userDefaultsClient: .unimplemented,
		walletLoader: .unimplemented,
		walletRemover: .unimplemented
	)
}
#endif
