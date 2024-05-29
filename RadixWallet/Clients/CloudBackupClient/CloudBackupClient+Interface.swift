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

	public init(
		startAutomaticBackups: @escaping StartAutomaticBackups,
		loadDeviceID: @escaping LoadDeviceID,
		migrateProfilesFromKeychain: @escaping MigrateProfilesFromKeychain,
		deleteProfileBackup: @escaping DeleteProfileBackup,
		checkAccountStatus: @escaping CheckAccountStatus,
		lastBackup: @escaping LastBackup,
		loadProfile: @escaping LoadProfile,
		loadAllProfiles: @escaping LoadAllProfiles
	) {
		self.startAutomaticBackups = startAutomaticBackups
		self.loadDeviceID = loadDeviceID
		self.migrateProfilesFromKeychain = migrateProfilesFromKeychain
		self.deleteProfileBackup = deleteProfileBackup
		self.checkAccountStatus = checkAccountStatus
		self.lastBackup = lastBackup
		self.loadProfile = loadProfile
		self.loadAllProfiles = loadAllProfiles
	}
}

extension CloudBackupClient {
	public typealias StartAutomaticBackups = @Sendable () async throws -> Void
	public typealias LoadDeviceID = @Sendable () async -> UUID?
	public typealias MigrateProfilesFromKeychain = @Sendable () async throws -> [CKRecord]
	public typealias DeleteProfileBackup = @Sendable (ProfileID) async throws -> Void
	public typealias CheckAccountStatus = @Sendable () async throws -> CKAccountStatus
	public typealias LastBackup = @Sendable (ProfileID) -> AnyAsyncSequence<BackupResult?>
	public typealias LoadProfile = @Sendable (ProfileID) async throws -> BackedupProfile?
	public typealias LoadAllProfiles = @Sendable () async throws -> [BackedupProfile]
}

// MARK: CloudBackupClient.BackedupProfile
extension CloudBackupClient {
	public struct BackedupProfile: Hashable, Sendable {
		public let profile: Profile
		public let containsLegacyP2PLinks: Bool
	}
}
