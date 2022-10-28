import AccountPortfolio
import AppSettings
import ComposableArchitecture
import Foundation
import KeychainClient
import PasteboardClient
import ProfileClient
import ProfileLoader
import UserDefaultsClient

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
		public var profileClient: ProfileClient

		public init(
			backgroundQueue: AnySchedulerOf<DispatchQueue>,
			mainQueue: AnySchedulerOf<DispatchQueue>,
			appSettingsClient: AppSettingsClient,
			accountPortfolioFetcher: AccountPortfolioFetcher,
			keychainClient: KeychainClient,
			pasteboardClient: PasteboardClient,
			profileLoader: ProfileLoader,
			userDefaultsClient: UserDefaultsClient,
			profileClient: ProfileClient
		) {
			self.backgroundQueue = backgroundQueue
			self.mainQueue = mainQueue
			self.appSettingsClient = appSettingsClient
			self.accountPortfolioFetcher = accountPortfolioFetcher
			self.keychainClient = keychainClient
			self.pasteboardClient = pasteboardClient
			self.profileLoader = profileLoader
			self.userDefaultsClient = userDefaultsClient
			self.profileClient = profileClient
		}
	}
}

#if DEBUG
public extension App.Environment {
	static let noop = Self(
		backgroundQueue: .immediate,
		mainQueue: .immediate,
		appSettingsClient: .noop,
		accountPortfolioFetcher: .noop,
		keychainClient: .unimplemented,
		pasteboardClient: .noop,
		profileLoader: .unimplemented,
		userDefaultsClient: .noop,
		profileClient: .unimplemented
	)

	static let unimplemented = Self(
		backgroundQueue: .unimplemented,
		mainQueue: .unimplemented,
		appSettingsClient: .testValue,
		accountPortfolioFetcher: .testValue,
		keychainClient: .unimplemented,
		pasteboardClient: .testValue,
		profileLoader: .unimplemented,
		userDefaultsClient: .noop,
		profileClient: .unimplemented
	)
}
#endif
