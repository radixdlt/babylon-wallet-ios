import AccountWorthFetcher
import AppSettings
import ComposableArchitecture
import PasteboardClient
import ProfileLoader
import UserDefaultsClient
import WalletLoader

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

		public init(
			backgroundQueue: AnySchedulerOf<DispatchQueue>,
			mainQueue: AnySchedulerOf<DispatchQueue>,
			appSettingsClient: AppSettingsClient,
			accountWorthFetcher: AccountWorthFetcher,
			pasteboardClient: PasteboardClient,
			profileLoader: ProfileLoader,
			userDefaultsClient: UserDefaultsClient,
			walletLoader: WalletLoader
		) {
			self.backgroundQueue = backgroundQueue
			self.mainQueue = mainQueue
			self.appSettingsClient = appSettingsClient
			self.accountWorthFetcher = accountWorthFetcher
			self.pasteboardClient = pasteboardClient
			self.profileLoader = profileLoader
			self.userDefaultsClient = userDefaultsClient
			self.walletLoader = walletLoader
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
		walletLoader: .noop
	)

	static let unimplemented = Self(
		backgroundQueue: .unimplemented,
		mainQueue: .unimplemented,
		appSettingsClient: .unimplemented,
		accountWorthFetcher: .unimplemented,
		pasteboardClient: .unimplemented,
		profileLoader: .unimplemented,
		userDefaultsClient: .unimplemented,
		walletLoader: .unimplemented
	)
}
#endif
