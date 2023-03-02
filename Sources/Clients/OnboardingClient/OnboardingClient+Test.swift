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
		commitEphemeral: unimplemented("\(Self.self).commitEphemeral"),
		createNewUnsavedVirtualEntity: unimplemented("\(Self.self).createNewUnsavedVirtualEntity"),
		saveNewVirtualEntity: unimplemented("\(Self.self).saveNewVirtualEntity"),
		importProfileSnapshot: unimplemented("\(Self.self).importProfileSnapshot")
	)

	public static let noop = Self(
		loadProfile: { .newUser },
		commitEphemeral: {},
		createNewUnsavedVirtualEntity: { _ in throw NoopError() }
        saveNewVirtualEntity: { _ in throw NoopError() },
		importProfileSnapshot: { _ in throw NoopError() }
	)
}
