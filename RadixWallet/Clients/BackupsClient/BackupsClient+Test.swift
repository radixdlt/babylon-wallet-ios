
extension DependencyValues {
	public var backupsClient: BackupsClient {
		get { self[BackupsClient.self] }
		set { self[BackupsClient.self] = newValue }
	}
}

// MARK: - BackupsClient + TestDependencyKey
extension BackupsClient: TestDependencyKey {
	public static let previewValue = Self.noop

	public static let testValue = Self(
		snapshotOfProfileForExport: unimplemented("\(Self.self).snapshotOfProfileForExport"),
		importProfileSnapshot: unimplemented("\(Self.self).importProfileSnapshot"),
		didExportProfileSnapshot: unimplemented("\(Self.self).didExportProfileSnapshot"),
		loadDeviceID: unimplemented("\(Self.self).loadDeviceID")
	)

	public static let noop = Self(
		snapshotOfProfileForExport: { throw NoopError() },
		importProfileSnapshot: { _, _, _ in throw NoopError() },
		didExportProfileSnapshot: { _ in throw NoopError() },
		loadDeviceID: { nil }
	)
}
