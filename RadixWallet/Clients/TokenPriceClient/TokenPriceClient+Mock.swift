// MARK: - TokenPricesClient + TestDependencyKey
extension TokenPricesClient: TestDependencyKey {
	public static let previewValue = Self.noop()

	public static let testValue = Self(
		getTokenPrices: unimplemented("\(Self.self).getTokenPrices")
	)

	private static func noop() -> Self {
		.init(
			getTokenPrices: { _ in [:] }
		)
	}
}

extension DependencyValues {
	public var tokenPricesClient: TokenPricesClient {
		get { self[TokenPricesClient.self] }
		set { self[TokenPricesClient.self] = newValue }
	}
}
