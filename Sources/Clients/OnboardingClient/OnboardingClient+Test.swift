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
		loadProfileBackups: unimplemented("\(Self.self).loadProfile"),
		importProfileSnapshot: unimplemented("\(Self.self).importProfileSnapshot"),
		importCloudProfile: unimplemented("\(Self.self).importCloudProfile"),
		commitEphemeral: unimplemented("\(Self.self).commitEphemeral"),
		loadDeviceID: unimplemented("\(Self.self).loadDeviceID")
	)

	public static let noop = Self(
		loadProfile: { .newUser },
		loadProfileBackups: { nil },
		importProfileSnapshot: { _ in throw NoopError() },
		importCloudProfile: { _ in throw NoopError() },
		commitEphemeral: {},
		loadDeviceID: { nil }
	)
}
