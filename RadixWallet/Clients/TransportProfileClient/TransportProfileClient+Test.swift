
extension DependencyValues {
	public var transportProfileClient: TransportProfileClient {
		get { self[TransportProfileClient.self] }
		set { self[TransportProfileClient.self] = newValue }
	}
}

// MARK: - TransportProfileClient + TestDependencyKey
extension TransportProfileClient: TestDependencyKey {
	public static let previewValue = Self.noop

	public static let testValue = Self(
		importProfile: unimplemented("\(Self.self).importProfile"),
		profileForExport: unimplemented("\(Self.self).profileForExport"),
		didExportProfile: unimplemented("\(Self.self).didExportProfile"),
		loadDeviceID: unimplemented("\(Self.self).loadDeviceID")
	)

	public static let noop = Self(
		importProfile: { _, _, _ in throw NoopError() },
		profileForExport: { throw NoopError() },
		didExportProfile: { _ in throw NoopError() },
		loadDeviceID: { nil }
	)
}
