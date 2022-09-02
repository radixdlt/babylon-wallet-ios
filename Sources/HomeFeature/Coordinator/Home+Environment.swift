import AppSettings
import ComposableArchitecture
import Foundation

public extension Home {
	// MARK: Environment
	struct Environment {
		public let appSettingsWorker: AppSettingsWorker
		public let aggregatedValueWorker: AggregatedValueWorker

		public init(
			appSettingsWorker: AppSettingsWorker = .init(),
			aggregatedValueWorker: AggregatedValueWorker = .init()
		) {
			self.appSettingsWorker = appSettingsWorker
			self.aggregatedValueWorker = aggregatedValueWorker
		}
	}
}

#if DEBUG
public extension Home.Environment {
	static let placeholder: Self = .init()
}
#endif
