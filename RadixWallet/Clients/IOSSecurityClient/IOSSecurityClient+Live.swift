import IOSSecuritySuite

extension IOSSecurityClient: DependencyKey {
	static let liveValue = Self(
		isJailbroken: {
			IOSSecuritySuite.amIJailbroken()
		}
	)
}
