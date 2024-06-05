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
		startAutomaticBackups: {},
		loadDeviceID: { nil },
		migrateProfilesFromKeychain: { throw NoopError() },
		deleteProfileBackup: { _ in },
		checkAccountStatus: { throw NoopError() },
		lastBackup: { _ in AsyncLazySequence([]).eraseToAnyAsyncSequence() },
		loadProfile: { _ in throw NoopError() },
		loadProfileHeaders: { throw NoopError() },
		reclaimProfile: { throw NoopError() }
	)

	public static let testValue = Self(
		startAutomaticBackups: unimplemented("\(Self.self).startAutomaticBackups"),
		loadDeviceID: unimplemented("\(Self.self).loadDeviceID"),
		migrateProfilesFromKeychain: unimplemented("\(Self.self).migrateProfilesFromKeychain"),
		deleteProfileBackup: unimplemented("\(Self.self).deleteProfileBackup"),
		checkAccountStatus: unimplemented("\(Self.self).checkAccountStatus"),
		lastBackup: unimplemented("\(Self.self).lastBackup"),
		loadProfile: unimplemented("\(Self.self).loadProfile"),
		loadProfileHeaders: unimplemented("\(Self.self).loadProfileHeaders"),
		reclaimProfile: unimplemented("\(Self.self).reclaimProfile")
	)
}
