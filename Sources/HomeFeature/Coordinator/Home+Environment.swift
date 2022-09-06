import AccountWorthFetcher
import AppSettings
import ComposableArchitecture
import Foundation

public extension Home {
	// MARK: Environment
	struct Environment {
		public let appSettingsClient: AppSettingsClient
		public let accountWorthFetcher: AccountWorthFetcher

		public init(
			appSettingsClient: AppSettingsClient = .live(),
			accountWorthFetcher: AccountWorthFetcher = .live()
		) {
			self.appSettingsClient = appSettingsClient
			self.accountWorthFetcher = accountWorthFetcher
		}
	}
}

#if DEBUG
public extension Home.Environment {
	static let placeholder: Self = .init()
}
#endif
