
extension DependencyValues {
	var urlFormatterClient: URLFormatterClient {
		get { self[URLFormatterClient.self] }
		set { self[URLFormatterClient.self] = newValue }
	}
}

// MARK: - URLFormatterClient + TestDependencyKey
extension URLFormatterClient: TestDependencyKey {
	static let previewValue = Self.noop

	static let testValue = Self(
		fixedSizeImage: unimplemented("\(Self.self).fixedSize", placeholder: noop.fixedSizeImage),
		generalImage: unimplemented("\(Self.self).general", placeholder: noop.generalImage)
	)

	static let noop = Self(
		fixedSizeImage: { url, _ in url },
		generalImage: { url in url }
	)
}
