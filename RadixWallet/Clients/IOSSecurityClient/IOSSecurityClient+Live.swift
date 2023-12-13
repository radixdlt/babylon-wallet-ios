import IOSSecuritySuite

extension IOSSecurityClient: DependencyKey {
	public static let liveValue = Self(
		isJailbroken: {
			IOSSecuritySuite.amIJailbroken()
		}
	)
}
