
extension DependencyValues {
	var transportProfileClient: TransportProfileClient {
		get { self[TransportProfileClient.self] }
		set { self[TransportProfileClient.self] = newValue }
	}
}

// MARK: - TransportProfileClient + TestDependencyKey
extension TransportProfileClient: TestDependencyKey {
	static let previewValue = Self.noop

	static let testValue = Self(
		importProfile: unimplemented("\(Self.self).importProfile"),
		profileForExport: unimplemented("\(Self.self).profileForExport"),
		didExportProfile: unimplemented("\(Self.self).didExportProfile")
	)

	static let noop = Self(
		importProfile: { _, _, _, _ in throw NoopError() },
		profileForExport: { throw NoopError() },
		didExportProfile: { _ in throw NoopError() }
	)
}
