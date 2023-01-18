import FeaturePrelude
import ProfileClient

// MARK: Splash.State
public extension Splash {
	// MARK: State
	struct State: Equatable {
		public var biometricsCheckFailedAlert: AlertState<Action.ViewAction.BiometricsCheckFailedAlertAction>?
		public var loadProfileResult: ProfileClient.LoadProfileResult?

		public init(
			biometricsCheckFailedAlert: AlertState<Action.ViewAction.BiometricsCheckFailedAlertAction>? = nil,
			profileResult loadProfileResult: ProfileClient.LoadProfileResult? = nil
		) {
			self.biometricsCheckFailedAlert = biometricsCheckFailedAlert
			self.loadProfileResult = loadProfileResult
		}
	}
}
