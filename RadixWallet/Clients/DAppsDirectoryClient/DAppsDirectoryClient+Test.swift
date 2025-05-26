extension DependencyValues {
	public var dAppsDirectoryClient: DAppsDirectoryClient {
		get { self[DAppsDirectoryClient.self] }
		set { self[DAppsDirectoryClient.self] = newValue }
	}
}

// MARK: - DAppsDirectoryClient + TestDependencyKey
extension DAppsDirectoryClient: TestDependencyKey {
	public static let previewValue = Self(fetchDApps: { [] })
	public static let testValue = Self(fetchDApps: { [] })
}
