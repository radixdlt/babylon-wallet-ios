import AppSettings
import ComposableArchitecture
import Foundation

public extension Home {
	// MARK: Environment
	struct Environment {
		public let appSettingsClient: AppSettingsClient
		public let aggregatedValueWorker: AggregatedValueWorker

		public init(
			appSettingsClient: AppSettingsClient = .init(),
			aggregatedValueWorker: AggregatedValueWorker = .init()
		) {
			self.appSettingsClient = appSettingsClient
			self.aggregatedValueWorker = aggregatedValueWorker
		}
	}
}

#if DEBUG
public extension Home.Environment {
	static let placeholder: Self = .init()
}
#endif
