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
		lookupProfileSnapshotByHeader: unimplemented("\(Self.self).lookupProfileSnapshotByHeader"),
		importProfileSnapshot: unimplemented("\(Self.self).importProfileSnapshot"),
		importCloudProfile: unimplemented("\(Self.self).importCloudProfile"),
		loadDeviceID: unimplemented("\(Self.self).loadDeviceID"),
		reclaimProfileOnThisDevice: unimplemented("\(Self.self).reclaimProfileOnThisDevice"),
		stopUsingProfileOnThisDevice: unimplemented("\(Self.self).stopUsingProfileOnThisDevice"),
		profileUsedOnOtherDevice: unimplemented("\(Self.self).profileUsedOnOtherDevice")
	)

	public static let noop = Self(
		snapshotOfProfileForExport: { throw NoopError() },
		loadProfileBackups: { nil },
		lookupProfileSnapshotByHeader: { _ in throw NoopError() },
		importProfileSnapshot: { _, _ in throw NoopError() },
		importCloudProfile: { _, _ in throw NoopError() },
		loadDeviceID: { nil },
		reclaimProfileOnThisDevice: {},
		stopUsingProfileOnThisDevice: {},
		profileUsedOnOtherDevice: { AsyncLazySequence([]).eraseToAnyAsyncSequence() }
	)
}
