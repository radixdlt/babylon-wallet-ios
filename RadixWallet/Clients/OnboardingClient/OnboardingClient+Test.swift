
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
		unlockApp: unimplemented("\(Self.self).unlockApp"),
		loadProfile: unimplemented("\(Self.self).loadProfile"),
		finishOnboarding: unimplemented("\(Self.self).finishOnboarding")
	)

	public static let noop = Self(
		unlockApp: { fatalError("noop") },
		loadProfile: { fatalError("noop") },
		finishOnboarding: { EqVoid.instance }
	)
}
