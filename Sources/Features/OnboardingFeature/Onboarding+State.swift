import ComposableArchitecture
import ImportProfileFeature

// MARK: Onboarding.State
public extension Onboarding {
	// MARK: State
	struct State: Equatable {
		public var importProfile: ImportProfile.State?

		public init(
			importProfile: ImportProfile.State? = nil
		) {
			self.importProfile = importProfile
		}
	}
}
