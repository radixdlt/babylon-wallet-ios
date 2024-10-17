import CloudKit
import ComposableArchitecture
import DependenciesAdditions
import os

// MARK: - CloudBackupClient
struct CloudBackupClient: DependencyKey, Sendable {
	let isCloudProfileSyncEnabled: IsCloudProfileSyncEnabled
	let startAutomaticBackups: StartAutomaticBackups
	let migrateProfilesFromKeychain: MigrateProfilesFromKeychain
	let deleteProfileBackup: DeleteProfileBackup
	let checkAccountStatus: CheckAccountStatus
	let lastBackup: LastBackup
	let loadProfile: LoadProfile
	let loadProfileHeaders: LoadProfileHeaders
	let claimProfileOnICloud: ClaimProfileOnICloud

	init(
		isCloudProfileSyncEnabled: @escaping IsCloudProfileSyncEnabled,
		startAutomaticBackups: @escaping StartAutomaticBackups,
		migrateProfilesFromKeychain: @escaping MigrateProfilesFromKeychain,
		deleteProfileBackup: @escaping DeleteProfileBackup,
		checkAccountStatus: @escaping CheckAccountStatus,
		lastBackup: @escaping LastBackup,
		loadProfile: @escaping LoadProfile,
		loadProfileHeaders: @escaping LoadProfileHeaders,
		claimProfileOnICloud: @escaping ClaimProfileOnICloud
	) {
		self.isCloudProfileSyncEnabled = isCloudProfileSyncEnabled
		self.startAutomaticBackups = startAutomaticBackups
		self.migrateProfilesFromKeychain = migrateProfilesFromKeychain
		self.deleteProfileBackup = deleteProfileBackup
		self.checkAccountStatus = checkAccountStatus
		self.lastBackup = lastBackup
		self.loadProfile = loadProfile
		self.loadProfileHeaders = loadProfileHeaders
		self.claimProfileOnICloud = claimProfileOnICloud
	}
}

extension CloudBackupClient {
	typealias IsCloudProfileSyncEnabled = @Sendable () async -> AnyAsyncSequence<Bool>
	typealias StartAutomaticBackups = @Sendable () async throws -> Void
	typealias MigrateProfilesFromKeychain = @Sendable () async throws -> [CKRecord]
	typealias DeleteProfileBackup = @Sendable (ProfileID?) async throws -> Void
	typealias CheckAccountStatus = @Sendable () async throws -> CKAccountStatus
	typealias LastBackup = @Sendable (ProfileID) -> AnyAsyncSequence<BackupResult?>
	typealias LoadProfile = @Sendable (ProfileID) async throws -> BackedUpProfile
	typealias LoadProfileHeaders = @Sendable () async throws -> [Profile.Header]
	typealias ClaimProfileOnICloud = @Sendable (Profile) async throws -> Void
}

// MARK: CloudBackupClient.BackedUpProfile
extension CloudBackupClient {
	struct BackedUpProfile: Hashable, Sendable {
		let profile: Profile
		let containsLegacyP2PLinks: Bool
	}
}
