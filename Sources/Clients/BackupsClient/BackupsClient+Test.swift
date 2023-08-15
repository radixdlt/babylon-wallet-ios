import ClientPrelude

extension DependencyValues {
	public var backupsClient: BackupsClient {
		get { self[BackupsClient.self] }
		set { self[BackupsClient.self] = newValue }
	}
}

// MARK: - BackupsClient + TestDependencyKey
extension BackupsClient: TestDependencyKey {
	public static let previewValue: Self = .noop
	public static let testValue = Self(
		snapshotOfProfileForExport: unimplemented("\(Self.self).snapshotOfProfileForExport"),
		loadProfileBackups: unimplemented("\(Self.self).loadProfile"),
		importProfileSnapshot: unimplemented("\(Self.self).importProfileSnapshot"),
		importCloudProfile: unimplemented("\(Self.self).importCloudProfile"),
		loadDeviceID: unimplemented("\(Self.self).loadDeviceID")
	)

	public static let noop = Self(
		snapshotOfProfileForExport: { throw NoopError() },
		loadProfileBackups: { nil },
		importProfileSnapshot: { _, _ in throw NoopError() },
		importCloudProfile: { _, _ in throw NoopError() },
		loadDeviceID: { nil }
	)
}
