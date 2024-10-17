import CloudKit
import ComposableArchitecture
import DependenciesAdditions
import os

extension DependencyValues {
	var cloudBackupClient: CloudBackupClient {
		get { self[CloudBackupClient.self] }
		set { self[CloudBackupClient.self] = newValue }
	}
}

// MARK: - CloudBackupClient + TestDependencyKey
extension CloudBackupClient: TestDependencyKey {
	static let previewValue: Self = .noop

	static let noop = Self(
		isCloudProfileSyncEnabled: { AsyncLazySequence([]).eraseToAnyAsyncSequence() },
		startAutomaticBackups: {},
		migrateProfilesFromKeychain: { throw NoopError() },
		deleteProfileBackup: { _ in },
		checkAccountStatus: { throw NoopError() },
		lastBackup: { _ in AsyncLazySequence([]).eraseToAnyAsyncSequence() },
		loadProfile: { _ in throw NoopError() },
		loadProfileHeaders: { throw NoopError() },
		claimProfileOnICloud: { _ in throw NoopError() }
	)

	static let testValue = Self(
		isCloudProfileSyncEnabled: unimplemented("\(Self.self).isCloudProfileSyncEnabled"),
		startAutomaticBackups: unimplemented("\(Self.self).startAutomaticBackups"),
		migrateProfilesFromKeychain: unimplemented("\(Self.self).migrateProfilesFromKeychain"),
		deleteProfileBackup: unimplemented("\(Self.self).deleteProfileBackup"),
		checkAccountStatus: unimplemented("\(Self.self).checkAccountStatus"),
		lastBackup: unimplemented("\(Self.self).lastBackup"),
		loadProfile: unimplemented("\(Self.self).loadProfile"),
		loadProfileHeaders: unimplemented("\(Self.self).loadProfileHeaders"),
		claimProfileOnICloud: unimplemented("\(Self.self).claimProfileOnICloud")
	)
}
