import ClientPrelude

// MARK: - AppPreferencesClient + TestDependencyKey
extension AppPreferencesClient: TestDependencyKey {
	public static let previewValue = Self.noop

	public static let testValue = Self(
		loadPreferences: unimplemented("\(Self.self).loadPreferences"),
		savePreferences: unimplemented("\(Self.self).savePreferences"),
		extractProfileSnapshot: unimplemented("\(Self.self).extractProfileSnapshot"),
		deleteProfileAndFactorSources: unimplemented("\(Self.self).deleteProfileAndFactorSources")
	)
}

extension AppPreferencesClient {
	static let noop = Self(
		loadPreferences: { .default },
		savePreferences: { _ in },
		extractProfileSnapshot: { throw NoopError() },
		deleteProfileAndFactorSources: {}
	)
}
