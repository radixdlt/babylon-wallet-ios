import ClientPrelude

// MARK: - PlatformEnvironmentClient + TestDependencyKey
extension PlatformEnvironmentClient: TestDependencyKey {
	public static let testValue = Self(
		isSimulator: { false }
	)
}

public extension DependencyValues {
	var platformEnvironmentClient: PlatformEnvironmentClient {
		get { self[PlatformEnvironmentClient.self] }
		set { self[PlatformEnvironmentClient.self] = newValue }
	}
}
