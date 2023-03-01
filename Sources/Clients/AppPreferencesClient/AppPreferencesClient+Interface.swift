import ClientPrelude
import Profile

// MARK: - AppPreferencesClient
public struct AppPreferencesClient: Sendable {
	public var loadPreferences: LoadPreferences
	public var savePreferences: SavePreferences

	// FIXME: find a better home for this...? Should we have some actual `ProfileSnapshotClient`
	// for this and `delete` method?
	public var extractProfileSnapshot: ExtractProfileSnapshot
	public var deleteProfileAndFactorSources: DeleteProfileSnapshot

	public init(
		loadPreferences: @escaping LoadPreferences,
		savePreferences: @escaping SavePreferences,
		extractProfileSnapshot: @escaping ExtractProfileSnapshot,
		deleteProfileAndFactorSources: @escaping DeleteProfileSnapshot
	) {
		self.loadPreferences = loadPreferences
		self.savePreferences = savePreferences

		self.extractProfileSnapshot = extractProfileSnapshot
		self.deleteProfileAndFactorSources = deleteProfileAndFactorSources
	}
}

// MARK: - Typealias
extension AppPreferencesClient {
	public typealias LoadPreferences = @Sendable () async -> AppPreferences
	public typealias SavePreferences = @Sendable (AppPreferences) async throws -> Void
	public typealias ExtractProfileSnapshot = @Sendable () async throws -> ProfileSnapshot
	public typealias DeleteProfileSnapshot = @Sendable () async throws -> Void
}

extension AppPreferencesClient {
	/// Syntactic sugar for:
	///      var copy = try await loadPreferences()
	///      try await mutatePreferences(&copy)
	///      try await savePreferences(copy)
	public func updating<T>(
		_ mutatePreferences: @Sendable (inout AppPreferences) throws -> T
	) async throws -> T {
		var copy = await loadPreferences()
		let result = try mutatePreferences(&copy)
		try await savePreferences(copy)
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
