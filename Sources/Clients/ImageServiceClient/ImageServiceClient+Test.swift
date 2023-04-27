import ClientPrelude

extension DependencyValues {
	public var imageServiceClient: ImageServiceClient {
		get { self[ImageServiceClient.self] }
		set { self[ImageServiceClient.self] = newValue }
	}
}

// MARK: - ImageServiceClient + TestDependencyKey
extension ImageServiceClient: TestDependencyKey {
	public static let previewValue: Self = .noop

	public static let testValue = Self(
		fixedSize: unimplemented("\(Self.self).fixedSize")
	)

	public static let noop = Self(
		fixedSize: { url, _ in url }
	)
}
