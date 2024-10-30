
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
		loadProfileState: unimplemented("\(Self.self).loadProfileState"),
		createNewProfile: unimplemented("\(Self.self).createNewProfile"),
		finishOnboardingWithRecoveredAccountAndBDFS: unimplemented("\(Self.self).finishOnboardingWithRecoveredAccountAndBDFS")
	)

	static let noop = Self(
		loadProfileState: { fatalError("noop") },
		createNewProfile: { fatalError("noop") },
		finishOnboardingWithRecoveredAccountAndBDFS: { _ in }
	)
}
