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

	public struct ProfileMetadata: Hashable, Sendable {
		public let snapshotVersion: ProfileSnapshotVersion
		public let creatingDeviceID: UUID
		public let lastUsedOnDeviceID: UUID
		public let lastModified: Date
		public let numberOfPersonas: UInt16
		public let numberOfAccounts: UInt16

		public init(snapshotVersion: ProfileSnapshotVersion, creatingDeviceID: UUID, lastUsedOnDeviceID: UUID, lastModified: Date, numberOfPersonas: UInt16, numberOfAccounts: UInt16) {
			self.snapshotVersion = snapshotVersion
			self.creatingDeviceID = creatingDeviceID
			self.lastUsedOnDeviceID = lastUsedOnDeviceID
			self.lastModified = lastModified.roundedToMS
			self.numberOfPersonas = numberOfPersonas
			self.numberOfAccounts = numberOfAccounts
		}
	}
}

private extension Date {
	var roundedToMS: Date {
		Date(timeIntervalSince1970: 0.001 * (1000 * timeIntervalSince1970).rounded())
	}
}
