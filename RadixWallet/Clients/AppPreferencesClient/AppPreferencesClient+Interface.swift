// MARK: - AppPreferencesClient
struct AppPreferencesClient: Sendable {
	var appPreferenceUpdates: AppPreferenceUpdates
	var getPreferences: GetPreferences
	var updatePreferences: UpdatePreferences

	/// Sets the flag on the profile, does not delete old backups
	var setIsCloudBackupEnabled: SetIsCloudBackupEnabled

	// FIXME: find a better home for this...? Should we have some actual `ProfileSnapshotClient`
	// for this and `delete` method?
	var extractProfile: ExtractProfile
	var deleteProfileAndFactorSources: DeleteProfile

	init(
		appPreferenceUpdates: @escaping AppPreferenceUpdates,
		getPreferences: @escaping GetPreferences,
		updatePreferences: @escaping UpdatePreferences,
		extractProfile: @escaping ExtractProfile,
		deleteProfileAndFactorSources: @escaping DeleteProfile,
		setIsCloudBackupEnabled: @escaping SetIsCloudBackupEnabled
	) {
		self.appPreferenceUpdates = appPreferenceUpdates
		self.getPreferences = getPreferences
		self.updatePreferences = updatePreferences
		self.extractProfile = extractProfile
		self.deleteProfileAndFactorSources = deleteProfileAndFactorSources
		self.setIsCloudBackupEnabled = setIsCloudBackupEnabled
	}
}

// MARK: - Typealias
extension AppPreferencesClient {
	typealias AppPreferenceUpdates = @Sendable () async -> AnyAsyncSequence<AppPreferences>
	typealias SetIsCloudBackupEnabled = @Sendable (Bool) async throws -> Void
	typealias GetPreferences = @Sendable () async -> AppPreferences
	typealias UpdatePreferences = @Sendable (AppPreferences) async throws -> Void
	typealias ExtractProfile = @Sendable () async -> Profile
	typealias DeleteProfile = @Sendable () async throws -> Void
}

extension AppPreferencesClient {
	/// Syntactic sugar for:
	///      var copy = try await getPreferences()
	///      try await mutatePreferences(&copy)
	///      try await updatePreferences(copy)
	func updating<T>(
		_ mutatePreferences: @Sendable (inout AppPreferences) throws -> T
	) async throws -> T {
		var copy = await getPreferences()
		let result = try mutatePreferences(&copy)
		try await updatePreferences(copy)
		return result // in many cases `Void`.
	}

	func updatingDisplay<T>(
		_ mutateDisplay: @Sendable (inout AppDisplay) throws -> T
	) async throws -> T {
		try await updating { preferences in
			try mutateDisplay(&preferences.display)
		}
	}

	func isDeveloperModeEnabled() async -> Bool {
		await extractProfile().appPreferences.security.isDeveloperModeEnabled
	}

	func toggleIsCurrencyAmountVisible() async throws {
		try await updatingDisplay { display in
			display.isCurrencyAmountVisible.toggle()
		}
	}
}

// MARK: AppPreferencesClient.Error
extension AppPreferencesClient {
	enum Error: Swift.Error, LocalizedError {
		case loadFailed(reason: String)
		case saveFailed(reason: String)
	}
}

extension DependencyValues {
	var appPreferencesClient: AppPreferencesClient {
		get { self[AppPreferencesClient.self] }
		set { self[AppPreferencesClient.self] = newValue }
	}
}
