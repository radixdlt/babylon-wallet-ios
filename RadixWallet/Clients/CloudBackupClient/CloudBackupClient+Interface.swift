import CloudKit
import ComposableArchitecture
import DependenciesAdditions
import os

// MARK: - CloudBackupClient
public struct CloudBackupClient: DependencyKey, Sendable {
	public let migrateKeychainProfiles: MigrateKeychainProfiles
	public let checkAccountStatus: CheckAccountStatus
	public let lastBackup: LastBackup
	public let loadProfile: LoadProfile
	public let loadAllProfiles: LoadAllProfiles
	public let uploadProfile: UploadProfile
	public let deleteProfile: DeleteProfile

	public init(
		migrateKeychainProfiles: @escaping MigrateKeychainProfiles,
		checkAccountStatus: @escaping CheckAccountStatus,
		lastBackup: @escaping LastBackup,
		loadProfile: @escaping LoadProfile,
		loadAllProfiles: @escaping LoadAllProfiles,
		uploadProfile: @escaping UploadProfile,
		deleteProfile: @escaping DeleteProfile
	) {
		self.migrateKeychainProfiles = migrateKeychainProfiles
		self.checkAccountStatus = checkAccountStatus
		self.lastBackup = lastBackup
		self.loadProfile = loadProfile
		self.loadAllProfiles = loadAllProfiles
		self.uploadProfile = uploadProfile
		self.deleteProfile = deleteProfile
	}
}

extension CloudBackupClient {
	public typealias MigrateKeychainProfiles = @Sendable () async throws -> [CKRecord]
	public typealias CheckAccountStatus = @Sendable () async throws -> CKAccountStatus
	public typealias LastBackup = @Sendable (UUID) async throws -> Date?
	public typealias LoadProfile = @Sendable (UUID) async throws -> Profile?
	public typealias LoadAllProfiles = @Sendable () async throws -> [Profile]
	public typealias UploadProfile = @Sendable (Profile) async throws -> CKRecord
	public typealias DeleteProfile = @Sendable (UUID) async throws -> Void
}
