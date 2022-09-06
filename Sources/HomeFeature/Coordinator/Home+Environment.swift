import AccountValueFetcher
import AppSettings
import ComposableArchitecture
import Foundation

public extension Home {
	// MARK: Environment
	struct Environment {
		public let appSettingsClient: AppSettingsClient
		public let accountValueFetcher: AccountValueFetcher

		public init(
			appSettingsClient: AppSettingsClient = .live(),
			accountValueFetcher: AccountValueFetcher = .init()
		) {
			self.appSettingsClient = appSettingsClient
			self.accountValueFetcher = accountValueFetcher
		}
	}
}

#if DEBUG
public extension Home.Environment {
	static let placeholder: Self = .init()
}
#endif
