import ComposableArchitecture

// MARK: - Onboarding
/// Namespace for OnboardingFeature
public enum Onboarding {}

// MARK: Onboarding.State
public extension Onboarding {
	// MARK: State
	struct State: Equatable {
		@BindableState public var nameOfFirstAccount: String
		public var canProceed: Bool

		public init(
			nameOfFirstAccount: String = "",
			canProceed: Bool = false
		) {
			self.nameOfFirstAccount = nameOfFirstAccount
			self.canProceed = canProceed
		}
	}
}

#if DEBUG
public extension Onboarding.State {
	static let placeholder = Self(
		nameOfFirstAccount: "Main",
		canProceed: true
	)
}
#endif
