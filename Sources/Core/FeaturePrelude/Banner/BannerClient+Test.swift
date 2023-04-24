import Dependencies

// MARK: - BannerClient + TestDependencyKey
extension BannerClient: TestDependencyKey {
	public static let previewValue = Self.noop
	public static let testValue: Self = .init(
		setWindowScene: unimplemented("\(Self.self).setWindowScene"),
		presentBanner: unimplemented("\(Self.self).presentBanner")
	)
}

extension BannerClient {
	public static let noop: Self = .init(
		setWindowScene: { _ in },
		presentBanner: { _ in }
	)
}
