import ComposableArchitecture

// MARK: - Onboarding
/// Namespace for OnboardingFeature
public enum Onboarding {}

public extension Onboarding {
	// MARK: State
	struct State: Equatable {
		// Just for initial testing
		@BindableState public var profileName: String
		public var canProceed: Bool

		public init(
			profileName: String = "",
			canProceed: Bool = false
		) {
			self.profileName = profileName
			self.canProceed = canProceed
		}
	}
}

#if DEBUG
public extension Onboarding.State {
	static let placeholder = Self(
		profileName: "Profile",
		canProceed: true
	)
}
#endif
