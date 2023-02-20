import ClientPrelude

extension DependencyValues {
	public var useFactorSourceClient: UseFactorSourceClient {
		get { self[UseFactorSourceClient.self] }
		set { self[UseFactorSourceClient.self] = newValue }
	}
}

// MARK: - UseFactorSourceClient + TestDependencyKey
extension UseFactorSourceClient: TestDependencyKey {
	public static let previewValue = Self.noop

	public static let noop = Self(
		publicKeyFromOnDeviceHD: { _ in throw NoopError() },
		signatureFromOnDeviceHD: { _ in throw NoopError() }
	)

	public static let testValue = Self(
		publicKeyFromOnDeviceHD: unimplemented("\(Self.self).publicKeyFromOnDeviceHD"),
		signatureFromOnDeviceHD: unimplemented("\(Self.self).signatureFromOnDeviceHD")
	)
}
