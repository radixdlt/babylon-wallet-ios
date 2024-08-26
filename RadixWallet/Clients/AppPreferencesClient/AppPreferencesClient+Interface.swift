// MARK: - AppPreferencesClient
public struct AppPreferencesClient: Sendable {
	public var appPreferenceUpdates: AppPreferenceUpdates
	public var getPreferences: GetPreferences
	public var updatePreferences: UpdatePreferences

	/// Sets the flag on the profile, does not delete old backups
	public var setIsCloudBackupEnabled: SetIsCloudBackupEnabled

	// FIXME: find a better home for this...? Should we have some actual `ProfileSnapshotClient`
	// for this and `delete` method?
	public var extractProfile: ExtractProfile
	public var deleteProfileAndFactorSources: DeleteProfile

	public init(
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
	public typealias AppPreferenceUpdates = @Sendable () async -> AnyAsyncSequence<AppPreferences>
	public typealias SetIsCloudBackupEnabled = @Sendable (Bool) async throws -> Void
	public typealias GetPreferences = @Sendable () async -> AppPreferences
	public typealias UpdatePreferences = @Sendable (AppPreferences) async throws -> Void
	public typealias ExtractProfile = @Sendable () async -> Profile
	public typealias DeleteProfile = @Sendable (_ keepInICloudIfPresent: Bool) async throws -> Void
}

extension AppPreferencesClient {
	/// Syntactic sugar for:
	///      var copy = try await getPreferences()
	///      try await mutatePreferences(&copy)
	///      try await updatePreferences(copy)
	public func updating<T>(
		_ mutatePreferences: @Sendable (inout AppPreferences) throws -> T
	) async throws -> T {
		var copy = await getPreferences()
		let result = try mutatePreferences(&copy)
		try await updatePreferences(copy)
		return result // in many cases `Void`.
	}

	public func updatingDisplay<T>(
		_ mutateDisplay: @Sendable (inout AppDisplay) throws -> T
	) async throws -> T {
		try await updating { preferences in
			try mutateDisplay(&preferences.display)
		}
	}

	public func isDeveloperModeEnabled() async -> Bool {
		await extractProfile().appPreferences.security.isDeveloperModeEnabled
	}

	public func toggleIsCurrencyAmountVisible() async throws {
		try await updatingDisplay { display in
			display.isCurrencyAmountVisible.toggle()
		}
	}

	public func getHiddenResources() async -> [ResourceIdentifier] {
		await getPreferences().resources.hiddenResources
	}

	public func isResourceHidden(_ resource: ResourceIdentifier) async -> Bool {
		await getHiddenResources().contains(resource)
	}
}

// MARK: AppPreferencesClient.Error
extension AppPreferencesClient {
	public enum Error: Swift.Error, LocalizedError {
		case loadFailed(reason: String)
		case saveFailed(reason: String)
	}
}

extension DependencyValues {
	public var appPreferencesClient: AppPreferencesClient {
		get { self[AppPreferencesClient.self] }
		set { self[AppPreferencesClient.self] = newValue }
	}
}
