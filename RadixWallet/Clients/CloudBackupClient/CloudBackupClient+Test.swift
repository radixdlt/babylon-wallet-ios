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
		checkAccountStatus: { throw NoopError() },
		lastBackup: { _ in throw NoopError() },
		queryProfile: { _ in throw NoopError() },
		queryAllProfiles: { throw NoopError() },
		uploadProfile: { _ in throw NoopError() },
		deleteProfile: { _ in }
	)

	public static let testValue = Self(
		checkAccountStatus: unimplemented("\(Self.self).checkAccountStatus"),
		lastBackup: unimplemented("\(Self.self).lastBackup"),
		queryProfile: unimplemented("\(Self.self).queryProfile"),
		queryAllProfiles: unimplemented("\(Self.self).queryAllProfiles"),
		uploadProfile: unimplemented("\(Self.self).uploadProfile"),
		deleteProfile: unimplemented("\(Self.self).deleteProfile")
	)
}
