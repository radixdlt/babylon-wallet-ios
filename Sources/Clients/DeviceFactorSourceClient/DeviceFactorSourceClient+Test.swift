import ClientPrelude

extension DependencyValues {
	public var deviceFactorSourceClient: DeviceFactorSourceClient {
		get { self[DeviceFactorSourceClient.self] }
		set { self[DeviceFactorSourceClient.self] = newValue }
	}
}

// MARK: - DeviceFactorSourceClient + TestDependencyKey
extension DeviceFactorSourceClient: TestDependencyKey {
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
