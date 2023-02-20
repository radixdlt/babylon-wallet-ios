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
		onDeviceHDPublicKey: { _ in throw NoopError() }
	)

	public static let testValue = Self(
		onDeviceHDPublicKey: unimplemented("\(Self.self).onDeviceHDPublicKey")
	)
}
