import ComposableArchitecture
import Foundation
import ProfileLoader

public extension Splash {
	// MARK: Environment
	struct Environment {
		public let backgroundQueue: AnySchedulerOf<DispatchQueue>
		public let mainQueue: AnySchedulerOf<DispatchQueue>
		public let profileLoader: ProfileLoader

		public init(
			backgroundQueue: AnySchedulerOf<DispatchQueue>,
			mainQueue: AnySchedulerOf<DispatchQueue>,
			profileLoader: ProfileLoader
		) {
			self.backgroundQueue = backgroundQueue
			self.mainQueue = mainQueue
			self.profileLoader = profileLoader
		}
	}
}
