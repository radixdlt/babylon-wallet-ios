import CloudKit
import ComposableArchitecture
import DependenciesAdditions
import os

// MARK: - CloudBackupClient
public struct CloudBackupClient: DependencyKey, Sendable {
	public let loadDeviceID: LoadDeviceID
	public let migrateProfilesFromKeychain: MigrateProfilesFromKeychain
	public let deleteProfileInKeychain: DeleteProfileInKeychain
	public let checkAccountStatus: CheckAccountStatus
	public let lastBackup: LastBackup
	public let loadProfile: LoadProfile
	public let loadAllProfiles: LoadAllProfiles
	public let backupProfile: BackupProfile

	public init(
		loadDeviceID: @escaping LoadDeviceID,
		migrateProfilesFromKeychain: @escaping MigrateProfilesFromKeychain,
		deleteProfileInKeychain: @escaping DeleteProfileInKeychain,
		checkAccountStatus: @escaping CheckAccountStatus,
		lastBackup: @escaping LastBackup,
		loadProfile: @escaping LoadProfile,
		loadAllProfiles: @escaping LoadAllProfiles,
		backupProfile: @escaping BackupProfile
	) {
		self.loadDeviceID = loadDeviceID
		self.migrateProfilesFromKeychain = migrateProfilesFromKeychain
		self.deleteProfileInKeychain = deleteProfileInKeychain
		self.checkAccountStatus = checkAccountStatus
		self.lastBackup = lastBackup
		self.loadProfile = loadProfile
		self.loadAllProfiles = loadAllProfiles
		self.backupProfile = backupProfile
	}
}

extension CloudBackupClient {
	public typealias LoadDeviceID = @Sendable () async -> UUID?
	public typealias MigrateProfilesFromKeychain = @Sendable () async throws -> [CKRecord]
	public typealias DeleteProfileInKeychain = @Sendable (UUID) async throws -> Void
	public typealias CheckAccountStatus = @Sendable () async throws -> CKAccountStatus
	public typealias LastBackup = @Sendable (UUID) -> AnyAsyncSequence<CloudBackup>
	public typealias LoadProfile = @Sendable (UUID) async throws -> Profile?
	public typealias LoadAllProfiles = @Sendable () async throws -> [Profile]
	public typealias BackupProfile = @Sendable () async throws -> CKRecord
}

// MARK: - CloudBackup
public struct CloudBackup: Codable, Sendable {
	public let profileModified: Date
	public let status: Status

	public enum Status: Codable, Sendable {
		case success
		case notAuthorized
		case failure
	}
}

extension UserDefaults.Dependency {
	public func setLastBackup(_ status: CloudBackup.Status, of profile: Profile) throws {
		var backups: [UUID: CloudBackup] = try loadCodable(key: .lastBackups) ?? [:]
		backups[profile.id] = .init(profileModified: profile.header.lastModified, status: status)
		try save(codable: backups, forKey: .lastBackups)
	}

	public func lastBackupValues(for profileID: ProfileID) -> AnyAsyncSequence<CloudBackup> {
		codableValues(key: .lastBackups, codable: [UUID: CloudBackup].self)
			.compactMap { (try? $0.get())?[profileID] }
			.eraseToAnyAsyncSequence()
	}
}
