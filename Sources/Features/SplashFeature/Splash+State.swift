import FeaturePrelude
import ProfileLoader

// MARK: Splash.State
public extension Splash {
	// MARK: State
	struct State: Equatable {
		public var alert: AlertState<Action.ViewAction>?
		public var profileResult: ProfileLoader.ProfileResult?

		public init(
			alert: AlertState<Action.ViewAction>? = nil,
			profileResult: ProfileLoader.ProfileResult? = nil
		) {
			self.alert = alert
			self.profileResult = profileResult
		}
	}
}
