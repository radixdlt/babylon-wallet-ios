import AccountWorthFetcher
import AppSettings
import ComposableArchitecture
import Foundation
import PasteboardClient

public extension Home {
	// MARK: Environment
	struct Environment {
		public let appSettingsClient: AppSettingsClient
		public let accountWorthFetcher: AccountWorthFetcher
		public let pasteboardClient: PasteboardClient

		public init(
			appSettingsClient: AppSettingsClient = .live(),
			accountWorthFetcher: AccountWorthFetcher = .live(),
			pasteboardClient: PasteboardClient
		) {
			self.appSettingsClient = appSettingsClient
			self.accountWorthFetcher = accountWorthFetcher
			self.pasteboardClient = pasteboardClient
		}
	}
}

#if DEBUG
public extension Home.Environment {
	static let placeholder: Self = .init(pasteboardClient: .noop)
}
#endif
