import ClientPrelude

extension DependencyValues {
	public var qrGeneratorClient: QRGeneratorClient {
		get { self[QRGeneratorClient.self] }
		set { self[QRGeneratorClient.self] = newValue }
	}
}

// MARK: - QRGeneratorClient + TestDependencyKey
extension QRGeneratorClient: TestDependencyKey {
	public static let previewValue: Self = .noop
	public static let testValue = Self(
		generate: unimplemented("\(Self.self).generate")
	)

	public static let noop = Self(
		generate: { _ in throw NoopError() }
	)
}
