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
		queryProfile: { _ in throw NoopError() },
		uploadProfile: { _ in throw NoopError() },
		queryAllProfiles: { throw NoopError() },
		deleteProfile: { _ in }
	)

	public static let testValue = Self(
		checkAccountStatus: unimplemented("\(Self.self).checkAccountStatus"),
		queryProfile: unimplemented("\(Self.self).queryProfile"),
		uploadProfile: unimplemented("\(Self.self).uploadProfile"),
		queryAllProfiles: unimplemented("\(Self.self).queryAllProfiles"),
		deleteProfile: unimplemented("\(Self.self).deleteProfile")
	)
}
