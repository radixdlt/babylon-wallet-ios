
extension DependencyValues {
	public var onboardingClient: OnboardingClient {
		get { self[OnboardingClient.self] }
		set { self[OnboardingClient.self] = newValue }
	}
}

// MARK: - OnboardingClient + TestDependencyKey
extension OnboardingClient: TestDependencyKey {
	public static let previewValue: Self = .noop
	public static let testValue = Self(
		unlockedApp: unimplemented("\(Self.self).unlockedApp"),
		loadProfile: unimplemented("\(Self.self).loadProfile"),
		finishedOnboarding: unimplemented("\(Self.self).finishedOnboarding")
	)

	public static let noop = Self(
		unlockedApp: { fatalError("noop") },
		loadProfile: { fatalError("noop") },
		finishedOnboarding: { EqVoid.instance }
	)
}
