// MARK: - IOSSecurityClient + TestDependencyKey
extension IOSSecurityClient: TestDependencyKey {
	static let previewValue = Self.noop

	static let testValue = Self(
		isJailbroken: unimplemented("\(Self.self).isJailbroken", placeholder: noop.isJailbroken)
	)
}

extension IOSSecurityClient {
	static let noop = Self(
		isJailbroken: { false }
	)
}
