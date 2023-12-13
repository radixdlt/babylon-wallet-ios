// MARK: - IOSSecurityClient + TestDependencyKey
extension IOSSecurityClient: TestDependencyKey {
	public static let previewValue = Self.noop

	public static let testValue = Self(
		isJailbroken: unimplemented("\(Self.self).isJailbroken")
	)
}

extension IOSSecurityClient {
	public static let noop = Self(
		isJailbroken: { false }
	)
}
