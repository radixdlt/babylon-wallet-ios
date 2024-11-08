// MARK: - TokenPricesClient + TestDependencyKey
extension TokenPricesClient: TestDependencyKey {
	static let previewValue = Self.noop()

	static let testValue = Self(
		getTokenPrices: unimplemented("\(Self.self).getTokenPrices")
	)

	private static func noop() -> Self {
		.init(
			getTokenPrices: { _, _ in [:] }
		)
	}
}

extension DependencyValues {
	var tokenPricesClient: TokenPricesClient {
		get { self[TokenPricesClient.self] }
		set { self[TokenPricesClient.self] = newValue }
	}
}
