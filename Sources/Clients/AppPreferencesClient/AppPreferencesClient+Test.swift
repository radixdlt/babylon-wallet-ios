import ClientPrelude

// MARK: - AppPreferencesClient + TestDependencyKey
extension AppPreferencesClient: TestDependencyKey {
	public static let previewValue = Self.noop

	public static let testValue = Self(
		loadPreferences: unimplemented("\(Self.self).loadPreferences"),
		savePreferences: unimplemented("\(Self.self).savePreferences")
	)
}

extension AppPreferencesClient {
	static let noop = Self(
		loadPreferences: { .default },
		savePreferences: { _ in }
	)
}
