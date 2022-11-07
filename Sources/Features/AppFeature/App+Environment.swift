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
		public var mainQueue: AnySchedulerOf<DispatchQueue>
		public let appSettingsClient: AppSettingsClient
		public let accountPortfolioFetcher: AccountPortfolioFetcher
		public let keychainClient: KeychainClient
		public let pasteboardClient: PasteboardClient
		public let profileLoader: ProfileLoader
		public let userDefaultsClient: UserDefaultsClient
		public var profileClient: ProfileClient

		public init(
			mainQueue: AnySchedulerOf<DispatchQueue>,
			appSettingsClient: AppSettingsClient,
			accountPortfolioFetcher: AccountPortfolioFetcher,
			keychainClient: KeychainClient,
			pasteboardClient: PasteboardClient,
			profileLoader: ProfileLoader,
			userDefaultsClient: UserDefaultsClient,
			profileClient: ProfileClient
		) {
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
		mainQueue: .immediate,
		appSettingsClient: .previewValue,
		accountPortfolioFetcher: .noop,
		keychainClient: .unimplemented,
		pasteboardClient: .previewValue,
		profileLoader: .testValue,
		userDefaultsClient: .noop,
		profileClient: .testValue
	)

	static let testValue = Self(
		mainQueue: .immediate,
		appSettingsClient: .testValue,
		accountPortfolioFetcher: .testValue,
		keychainClient: .unimplemented,
		pasteboardClient: .testValue,
		profileLoader: .testValue,
		userDefaultsClient: .noop,
		profileClient: .testValue
	)
}
#endif
