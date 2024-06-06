import CloudKit
import ComposableArchitecture
import DependenciesAdditions
import os

// MARK: - CloudBackupClient
public struct CloudBackupClient: DependencyKey, Sendable {
	public let startAutomaticBackups: StartAutomaticBackups
	public let loadDeviceID: LoadDeviceID
	public let migrateProfilesFromKeychain: MigrateProfilesFromKeychain
	public let deleteProfileBackup: DeleteProfileBackup
	public let checkAccountStatus: CheckAccountStatus
	public let lastBackup: LastBackup
	public let loadProfile: LoadProfile
	public let loadProfileHeaders: LoadProfileHeaders

	public init(
		startAutomaticBackups: @escaping StartAutomaticBackups,
		loadDeviceID: @escaping LoadDeviceID,
		migrateProfilesFromKeychain: @escaping MigrateProfilesFromKeychain,
		deleteProfileBackup: @escaping DeleteProfileBackup,
		checkAccountStatus: @escaping CheckAccountStatus,
		lastBackup: @escaping LastBackup,
		loadProfile: @escaping LoadProfile,
		loadProfileHeaders: @escaping LoadProfileHeaders
	) {
		self.startAutomaticBackups = startAutomaticBackups
		self.loadDeviceID = loadDeviceID
		self.migrateProfilesFromKeychain = migrateProfilesFromKeychain
		self.deleteProfileBackup = deleteProfileBackup
		self.checkAccountStatus = checkAccountStatus
		self.lastBackup = lastBackup
		self.loadProfile = loadProfile
		self.loadProfileHeaders = loadProfileHeaders
	}
}

extension CloudBackupClient {
	public typealias StartAutomaticBackups = @Sendable () async throws -> Void
	public typealias LoadDeviceID = @Sendable () async -> UUID?
	public typealias MigrateProfilesFromKeychain = @Sendable () async throws -> [CKRecord]
	public typealias DeleteProfileBackup = @Sendable (ProfileID) async throws -> Void
	public typealias CheckAccountStatus = @Sendable () async throws -> CKAccountStatus
	public typealias LastBackup = @Sendable (ProfileID) -> AnyAsyncSequence<BackupResult?>
	public typealias LoadProfile = @Sendable (ProfileID) async throws -> BackedUpProfile
	public typealias LoadProfileHeaders = @Sendable () async throws -> [Profile.Header]
}

// MARK: CloudBackupClient.BackedUpProfile
extension CloudBackupClient {
	public struct BackedUpProfile: Hashable, Sendable {
		public let profile: Profile
		public let containsLegacyP2PLinks: Bool
	}
}
