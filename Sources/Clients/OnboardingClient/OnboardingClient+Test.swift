import ClientPrelude

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
		loadProfile: unimplemented("\(Self.self).loadProfile"),
		commitEphemeral: unimplemented("\(Self.self).commitEphemeral")
	)

	public static let noop = Self(
		loadProfile: { .newUser },
		commitEphemeral: {}
	)
}
