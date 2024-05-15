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
	public let loadAllProfiles: LoadAllProfiles
	public let backupProfile: BackupProfile

	public init(
		startAutomaticBackups: @escaping StartAutomaticBackups,
		loadDeviceID: @escaping LoadDeviceID,
		migrateProfilesFromKeychain: @escaping MigrateProfilesFromKeychain,
		deleteProfileBackup: @escaping DeleteProfileBackup,
		checkAccountStatus: @escaping CheckAccountStatus,
		lastBackup: @escaping LastBackup,
		loadProfile: @escaping LoadProfile,
		loadAllProfiles: @escaping LoadAllProfiles,
		backupProfile: @escaping BackupProfile
	) {
		self.startAutomaticBackups = startAutomaticBackups
		self.loadDeviceID = loadDeviceID
		self.migrateProfilesFromKeychain = migrateProfilesFromKeychain
		self.deleteProfileBackup = deleteProfileBackup
		self.checkAccountStatus = checkAccountStatus
		self.lastBackup = lastBackup
		self.loadProfile = loadProfile
		self.loadAllProfiles = loadAllProfiles
		self.backupProfile = backupProfile
	}
}

extension CloudBackupClient {
	public typealias StartAutomaticBackups = @Sendable () async throws -> Void
	public typealias LoadDeviceID = @Sendable () async -> UUID?
	public typealias MigrateProfilesFromKeychain = @Sendable () async throws -> [CKRecord]
	public typealias DeleteProfileBackup = @Sendable (ProfileID) async throws -> Void
	public typealias CheckAccountStatus = @Sendable () async throws -> CKAccountStatus
	public typealias LastBackup = @Sendable (ProfileID) -> AnyAsyncSequence<BackupResult?>
	public typealias LoadProfile = @Sendable (ProfileID) async throws -> Profile?
	public typealias LoadAllProfiles = @Sendable () async throws -> [Profile]
	public typealias BackupProfile = @Sendable () async throws -> CKRecord
}
