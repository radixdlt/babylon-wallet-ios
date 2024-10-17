
extension DependencyValues {
	var onboardingClient: OnboardingClient {
		get { self[OnboardingClient.self] }
		set { self[OnboardingClient.self] = newValue }
	}
}

// MARK: - OnboardingClient + TestDependencyKey
extension OnboardingClient: TestDependencyKey {
	static let previewValue = Self.noop

	static let testValue = Self(
		loadProfile: unimplemented("\(Self.self).loadProfile"),
		finishOnboarding: unimplemented("\(Self.self).finishOnboarding"),
		finishOnboardingWithRecoveredAccountAndBDFS: unimplemented("\(Self.self).finishOnboardingWithRecoveredAccountAndBDFS")
	)

	static let noop = Self(
		loadProfile: { fatalError("noop") },
		finishOnboarding: { EqVoid.instance },
		finishOnboardingWithRecoveredAccountAndBDFS: { _ in EqVoid.instance }
	)
}
