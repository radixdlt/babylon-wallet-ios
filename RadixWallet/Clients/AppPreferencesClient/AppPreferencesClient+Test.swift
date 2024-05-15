// MARK: - AppPreferencesClient + TestDependencyKey
extension AppPreferencesClient: TestDependencyKey {
	public static let previewValue = Self.noop

	public static let testValue = Self(
		appPreferenceUpdates: unimplemented("\(Self.self).appPreferenceUpdates"),
		getPreferences: unimplemented("\(Self.self).getPreferences"),
		updatePreferences: unimplemented("\(Self.self).updatePreferences"),
		extractProfile: unimplemented("\(Self.self).extractProfile"),
		deleteProfileAndFactorSources: unimplemented("\(Self.self).deleteProfileAndFactorSources"),
		setIsCloudProfileSyncEnabled: unimplemented("\(Self.self).setIsCloudProfileSyncEnabled"),
		setIsCloudBackupEnabled: unimplemented("\(Self.self).setIsCloudBackupEnabled")
	)
}

extension AppPreferencesClient {
	public static let noop = Self(
		appPreferenceUpdates: { AsyncLazySequence([]).eraseToAnyAsyncSequence() },
		getPreferences: { .default },
		updatePreferences: { _ in },
		extractProfile: { fatalError() },
		deleteProfileAndFactorSources: { _ in },
		setIsCloudProfileSyncEnabled: { _ in },
		setIsCloudBackupEnabled: { _ in }
	)
}
