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
		loadProfileBackups: unimplemented("\(Self.self).loadProfile"),
		importProfileSnapshot: unimplemented("\(Self.self).importProfileSnapshot"),
		importCloudProfile: unimplemented("\(Self.self).importCloudProfile"),
		loadDeviceID: unimplemented("\(Self.self).loadDeviceID")
	)

	public static let noop = Self(
		loadProfileBackups: { nil },
		importProfileSnapshot: { _ in throw NoopError() },
		importCloudProfile: { _ in throw NoopError() },
		loadDeviceID: { nil }
	)
}
