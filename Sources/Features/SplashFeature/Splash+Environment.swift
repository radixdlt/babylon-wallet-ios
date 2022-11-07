import ComposableArchitecture
import Foundation
import ProfileLoader

public extension Splash {
	// MARK: Environment
	struct Environment {
		public let mainQueue: AnySchedulerOf<DispatchQueue>
		public let profileLoader: ProfileLoader

		public init(
			mainQueue: AnySchedulerOf<DispatchQueue>,
			profileLoader: ProfileLoader
		) {
			self.mainQueue = mainQueue
			self.profileLoader = profileLoader
		}
	}
}
