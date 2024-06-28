// MARK: - DeepLinkHandlerClient + TestDependencyKey
extension DeepLinkHandlerClient: TestDependencyKey {
	public static let previewValue = Self.noop

	public static let testValue = Self(
		handleDeepLink: unimplemented("\(Self.self).handleDeepLink"),
		setDeepLink: unimplemented("\(Self.self).setDeepLink"),
		hasDeepLink: unimplemented("\(Self.self).hasDeepLink")
	)
}

extension DeepLinkHandlerClient {
	public static let noop = Self(
		handleDeepLink: {},
		setDeepLink: { _ in },
		hasDeepLink: { false }
	)
}
