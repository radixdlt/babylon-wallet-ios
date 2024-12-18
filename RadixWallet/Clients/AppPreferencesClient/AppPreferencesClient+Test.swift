// MARK: - AppPreferencesClient + TestDependencyKey
extension AppPreferencesClient: TestDependencyKey {
	static let previewValue = Self.noop

	static let testValue = Self(
		appPreferenceUpdates: unimplemented("\(Self.self).appPreferenceUpdates", placeholder: noop.appPreferenceUpdates),
		getPreferences: unimplemented("\(Self.self).getPreferences", placeholder: noop.getPreferences),
		updatePreferences: unimplemented("\(Self.self).updatePreferences"),
		extractProfile: unimplemented("\(Self.self).extractProfile", placeholder: noop.extractProfile),
		deleteProfileAndFactorSources: unimplemented("\(Self.self).deleteProfileAndFactorSources"),
		setIsCloudBackupEnabled: unimplemented("\(Self.self).setIsCloudBackupEnabled")
	)
}

extension AppPreferencesClient {
	static let noop = Self(
		appPreferenceUpdates: { AsyncLazySequence([]).eraseToAnyAsyncSequence() },
		getPreferences: { .default },
		updatePreferences: { _ in },
		extractProfile: { fatalError() },
		deleteProfileAndFactorSources: {},
		setIsCloudBackupEnabled: { _ in }
	)
}
