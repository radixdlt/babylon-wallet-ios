
extension DependencyValues {
	public var onboardingClient: OnboardingClient {
		get { self[OnboardingClient.self] }
		set { self[OnboardingClient.self] = newValue }
	}
}

// MARK: - OnboardingClient + TestDependencyKey
extension OnboardingClient: TestDependencyKey {
	public static let previewValue = Self.noop

	public static let testValue = Self(
		loadProfileState: unimplemented("\(Self.self).loadProfile"),
		finishOnboarding: unimplemented("\(Self.self).finishOnboarding"),
		finishOnboardingWithRecoveredAccountAndBDFS: unimplemented("\(Self.self).finishOnboardingWithRecoveredAccountAndBDFS")
	)

	public static let noop = Self(
		loadProfileState: { fatalError("noop") },
		finishOnboarding: { EqVoid.instance },
		finishOnboardingWithRecoveredAccountAndBDFS: { _ in EqVoid.instance }
	)
}
