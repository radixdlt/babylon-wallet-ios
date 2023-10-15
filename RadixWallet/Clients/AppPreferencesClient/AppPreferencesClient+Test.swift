// MARK: - AppPreferencesClient + TestDependencyKey
extension AppPreferencesClient: TestDependencyKey {
	public static let previewValue = Self.noop

	public static let testValue = Self(
		getPreferences: unimplemented("\(Self.self).getPreferences"),
		updatePreferences: unimplemented("\(Self.self).updatePreferences"),
		extractProfileSnapshot: unimplemented("\(Self.self).extractProfileSnapshot"),
		deleteProfileAndFactorSources: unimplemented("\(Self.self).deleteProfileAndFactorSources"),
		setIsCloudProfileSyncEnabled: unimplemented("\(Self.self).setIsCloudProfileSyncEnabled"),
		getDetailsOfSecurityStructure: unimplemented("\(Self.self).getDetailsOfSecurityStructure")
	)
}

extension AppPreferencesClient {
	public static let noop = Self(
		getPreferences: { .default },
		updatePreferences: { _ in },
		extractProfileSnapshot: { fatalError() },
		deleteProfileAndFactorSources: { _ in },
		setIsCloudProfileSyncEnabled: { _ in },
		getDetailsOfSecurityStructure: { _ in throw NoopError() }
	)
}
