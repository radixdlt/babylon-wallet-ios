import ComposableArchitecture
import Foundation
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

#if DEBUG
public extension Onboarding.Environment {
	static let unimplemented = Self(
		backgroundQueue: .unimplemented,
		mainQueue: .unimplemented,
		userDefaultsClient: .unimplemented
	)
}
#endif
