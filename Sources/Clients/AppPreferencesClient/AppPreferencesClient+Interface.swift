import ClientPrelude
import Profile

// MARK: - AppPreferencesClient
public struct AppPreferencesClient: Sendable {
	public var getPreferences: GetPreferences
	public var updatePreferences: UpdatePreferences

	// FIXME: find a better home for this...? Should we have some actual `ProfileSnapshotClient`
	// for this and `delete` method?
	public var extractProfileSnapshot: ExtractProfileSnapshot
	public var deleteProfileAndFactorSources: DeleteProfileSnapshot

	public init(
		getPreferences: @escaping GetPreferences,
		updatePreferences: @escaping UpdatePreferences,
		extractProfileSnapshot: @escaping ExtractProfileSnapshot,
		deleteProfileAndFactorSources: @escaping DeleteProfileSnapshot
	) {
		self.getPreferences = getPreferences
		self.updatePreferences = updatePreferences

		self.extractProfileSnapshot = extractProfileSnapshot
		self.deleteProfileAndFactorSources = deleteProfileAndFactorSources
	}
}

// MARK: - Typealias
extension AppPreferencesClient {
	public typealias GetPreferences = @Sendable () async -> AppPreferences
	public typealias UpdatePreferences = @Sendable (AppPreferences) async throws -> Void
	public typealias ExtractProfileSnapshot = @Sendable () async -> ProfileSnapshot
	public typealias DeleteProfileSnapshot = @Sendable (_ keepIcloudIfPresent: Bool) async throws -> Void
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
		_ mutateDisplay: @Sendable (inout AppPreferences.Display) throws -> T
	) async throws -> T {
		try await updating { preferences in
			try mutateDisplay(&preferences.display)
		}
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
