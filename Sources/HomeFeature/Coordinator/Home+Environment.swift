import AppSettings
import ComposableArchitecture
import Foundation

public extension Home {
	// MARK: Environment
	struct Environment {
		public let appSettingsWorker: AppSettingsWorker

		public init(
			appSettingsWorker: AppSettingsWorker = .init()
		) {
			self.appSettingsWorker = appSettingsWorker
		}
	}
}

#if DEBUG
public extension Home.Environment {
	static let placeholder: Self = .init()
}
#endif
