import AccountPortfolio
import AppSettings
import ComposableArchitecture
import Foundation
import KeychainClient
import PasteboardClient
import ProfileLoader
import UserDefaultsClient
import WalletClient

// MARK: - App.Environment
public extension App {
	// MARK: Environment
	struct Environment {
		public let backgroundQueue: AnySchedulerOf<DispatchQueue>
		public var mainQueue: AnySchedulerOf<DispatchQueue>
		public let appSettingsClient: AppSettingsClient
		public let accountPortfolioFetcher: AccountPortfolioFetcher
		public let keychainClient: KeychainClient
		public let pasteboardClient: PasteboardClient
		public let profileLoader: ProfileLoader
		public let userDefaultsClient: UserDefaultsClient
		public var walletClient: WalletClient

		public init(
			backgroundQueue: AnySchedulerOf<DispatchQueue>,
			mainQueue: AnySchedulerOf<DispatchQueue>,
			appSettingsClient: AppSettingsClient,
			accountPortfolioFetcher: AccountPortfolioFetcher,
			keychainClient: KeychainClient,
			pasteboardClient: PasteboardClient,
			profileLoader: ProfileLoader,
			userDefaultsClient: UserDefaultsClient,
			walletClient: WalletClient
		) {
			self.backgroundQueue = backgroundQueue
			self.mainQueue = mainQueue
			self.appSettingsClient = appSettingsClient
			self.accountPortfolioFetcher = accountPortfolioFetcher
			self.keychainClient = keychainClient
			self.pasteboardClient = pasteboardClient
			self.profileLoader = profileLoader
			self.userDefaultsClient = userDefaultsClient
			self.walletClient = walletClient
		}
	}
}

#if DEBUG
public extension App.Environment {
	static let noop = Self(
		backgroundQueue: .immediate,
		mainQueue: .immediate,
		appSettingsClient: .mock,
		accountPortfolioFetcher: .mock,
		keychainClient: .unimplemented,
		pasteboardClient: .noop,
		profileLoader: .unimplemented,
		userDefaultsClient: .noop,
		walletClient: .unimplemented
	)

	static let unimplemented = Self(
		backgroundQueue: .unimplemented,
		mainQueue: .unimplemented,
		appSettingsClient: .unimplemented,
		accountPortfolioFetcher: .unimplemented,
		keychainClient: .unimplemented,
		pasteboardClient: .unimplemented,
		profileLoader: .unimplemented,
		userDefaultsClient: .unimplemented,
		walletClient: .unimplemented
	)
}
#endif
