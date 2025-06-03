extension DependencyValues {
	public var radixNameService: RadixNameServiceClient {
		get { self[RadixNameServiceClient.self] }
		set { self[RadixNameServiceClient.self] = newValue }
	}
}

// MARK: - RadixNameService + TestDependencyKey
extension RadixNameServiceClient: TestDependencyKey {
	public static let previewValue = Self()
	public static let testValue = Self()
}
