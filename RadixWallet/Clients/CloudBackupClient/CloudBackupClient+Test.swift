import CloudKit
import ComposableArchitecture
import DependenciesAdditions
import os

extension DependencyValues {
	public var cloudBackupClient: CloudBackupClient {
		get { self[CloudBackupClient.self] }
		set { self[CloudBackupClient.self] = newValue }
	}
}

// MARK: - CloudBackupClient + TestDependencyKey
extension CloudBackupClient: TestDependencyKey {
	public static let previewValue: Self = .noop

	public static let noop = Self(
		loadDeviceID: { nil },
		migrateKeychainProfiles: { throw NoopError() },
		checkAccountStatus: { throw NoopError() },
		lastBackup: { _ in throw NoopError() },
		loadProfile: { _ in throw NoopError() },
		loadAllProfiles: { throw NoopError() },
		backupProfile: { _ in throw NoopError() },
		deleteProfile: { _ in }
	)

	public static let testValue = Self(
		loadDeviceID: unimplemented("\(Self.self).loadDeviceID"),
		migrateKeychainProfiles: unimplemented("\(Self.self).migrateKeychainProfiles"),
		checkAccountStatus: unimplemented("\(Self.self).checkAccountStatus"),
		lastBackup: unimplemented("\(Self.self).lastBackup"),
		loadProfile: unimplemented("\(Self.self).queryProfile"),
		loadAllProfiles: unimplemented("\(Self.self).queryAllProfiles"),
		backupProfile: unimplemented("\(Self.self).uploadProfile"),
		deleteProfile: unimplemented("\(Self.self).deleteProfile")
	)
}
