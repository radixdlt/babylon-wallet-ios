
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
		loadProfileState: unimplemented("\(Self.self).loadProfileState"),
		createNewProfile: unimplemented("\(Self.self).createNewProfile"),
		finishOnboardingWithRecoveredAccountAndBDFS: unimplemented("\(Self.self).finishOnboardingWithRecoveredAccountAndBDFS")
	)

	public static let noop = Self(
		loadProfileState: { fatalError("noop") },
		createNewProfile: { fatalError("noop") },
		finishOnboardingWithRecoveredAccountAndBDFS: { _ in }
	)
}
