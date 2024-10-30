// MARK: - DeepLinkHandlerClient + TestDependencyKey
extension DeepLinkHandlerClient: TestDependencyKey {
	static let previewValue = Self.noop

	static let testValue = Self(
		handleDeepLink: unimplemented("\(Self.self).handleDeepLink"),
		setDeepLink: unimplemented("\(Self.self).setDeepLink"),
		hasDeepLink: unimplemented("\(Self.self).hasDeepLink")
	)
}

extension DeepLinkHandlerClient {
	static let noop = Self(
		handleDeepLink: {},
		setDeepLink: { _ in },
		hasDeepLink: { false }
	)
}
