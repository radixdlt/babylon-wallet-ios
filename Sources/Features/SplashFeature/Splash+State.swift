import FeaturePrelude
import ProfileLoader

// MARK: Splash.State
public extension Splash {
	// MARK: State
	struct State: Equatable {
		public var biometricsCheckFailedAlert: AlertState<Action.ViewAction.BiometricsCheckFailedAlertAction>?
		public var profileResult: ProfileLoader.ProfileResult?

		public init(
			biometricsCheckFailedAlert: AlertState<Action.ViewAction.BiometricsCheckFailedAlertAction>? = nil,
			profileResult: ProfileLoader.ProfileResult? = nil
		) {
			self.biometricsCheckFailedAlert = biometricsCheckFailedAlert
			self.profileResult = profileResult
		}
	}
}
