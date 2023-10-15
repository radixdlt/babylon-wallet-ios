
extension DependencyValues {
	public var urlFormatterClient: URLFormatterClient {
		get { self[URLFormatterClient.self] }
		set { self[URLFormatterClient.self] = newValue }
	}
}

// MARK: - URLFormatterClient + TestDependencyKey
extension URLFormatterClient: TestDependencyKey {
	public static let previewValue: Self = .noop

	public static let testValue = Self(
		fixedSizeImage: unimplemented("\(Self.self).fixedSize"),
		generalImage: unimplemented("\(Self.self).general")
	)

	public static let noop = Self(
		fixedSizeImage: { url, _ in url },
		generalImage: { url in url }
	)
}
