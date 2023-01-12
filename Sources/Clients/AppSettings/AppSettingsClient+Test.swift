import Prelude

// MARK: - AppSettingsClient + TestDependencyKey
extension AppSettingsClient: TestDependencyKey {
	public static let previewValue = Self.noop

	public static let testValue = Self(
		saveSettings: unimplemented("\(Self.self).saveSettings"),
		loadSettings: unimplemented("\(Self.self).loadSettings")
	)
}

extension AppSettingsClient {
	static let noop = Self(
		saveSettings: { _ in },
		loadSettings: { .default }
	)
}
