import ComposableArchitecture
import UserDefaultsClient

public extension Onboarding {
	// MARK: Environment
	struct Environment {
		public let backgroundQueue: AnySchedulerOf<DispatchQueue>
		public let mainQueue: AnySchedulerOf<DispatchQueue>
		public let userDefaultsClient: UserDefaultsClient // replace with `ProfileCreator`

		public init(
			backgroundQueue: AnySchedulerOf<DispatchQueue>,
			mainQueue: AnySchedulerOf<DispatchQueue>,
			userDefaultsClient: UserDefaultsClient
		) {
			self.backgroundQueue = backgroundQueue
			self.mainQueue = mainQueue
			self.userDefaultsClient = userDefaultsClient
		}
	}
}
