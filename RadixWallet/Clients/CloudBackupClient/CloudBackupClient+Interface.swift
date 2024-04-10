import CloudKit
import ComposableArchitecture
import DependenciesAdditions
import os

// MARK: - CloudBackupClient
public struct CloudBackupClient: DependencyKey {
	public let checkAccountStatus: CheckAccountStatus
	public let queryProfile: QueryProfile
	public let uploadProfile: UploadProfile
	public let queryAllProfiles: QueryAllProfiles
	public let deleteProfile: DeleteProfile
}

extension CloudBackupClient {
	public typealias CheckAccountStatus = () async throws -> CKAccountStatus
	public typealias QueryProfile = (UUID) async throws -> CKRecord?
	public typealias UploadProfile = (Profile) async throws -> CKRecord
	public typealias QueryAllProfiles = () async throws -> [Profile]
	public typealias DeleteProfile = (UUID) async throws -> Void
}
