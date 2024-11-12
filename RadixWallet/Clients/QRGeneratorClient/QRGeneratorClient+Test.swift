
extension DependencyValues {
	var qrGeneratorClient: QRGeneratorClient {
		get { self[QRGeneratorClient.self] }
		set { self[QRGeneratorClient.self] = newValue }
	}
}

// MARK: - QRGeneratorClient + TestDependencyKey
extension QRGeneratorClient: TestDependencyKey {
	static let previewValue = Self.noop

	static let testValue = Self(
		generate: unimplemented("\(Self.self).generate")
	)

	static let noop = Self(
		generate: { _ in throw NoopError() }
	)
}
