import CloudKit
import ComposableArchitecture
import DependenciesAdditions
import os

// MARK: - CloudBackupClient
public struct CloudBackupClient: DependencyKey {
	public let checkAccountStatus: CheckAccountStatus
	public let lastBackup: LastBackup
	public let queryProfile: QueryProfile
	public let queryAllProfiles: QueryAllProfiles
	public let uploadProfile: UploadProfile
	public let deleteProfile: DeleteProfile
}

extension CloudBackupClient {
	public typealias CheckAccountStatus = () async throws -> CKAccountStatus
	public typealias LastBackup = (UUID) async throws -> Date?
	public typealias QueryProfile = (UUID) async throws -> Profile?
	public typealias QueryAllProfiles = () async throws -> [Profile]
	public typealias UploadProfile = (Profile) async throws -> CKRecord
	public typealias DeleteProfile = (UUID) async throws -> Void
}
