// MARK: - TokenPricesClient + TestDependencyKey
extension TokenPricesClient: TestDependencyKey {
	static let previewValue = Self.noop()

	static let testValue = Self(
		getTokenPrices: unimplemented("\(Self.self).getTokenPrices"),
		getTokenPriceServices: unimplemented("\(Self.self).getTokenPriceServices"),
		addTokenPriceService: unimplemented("\(Self.self).addTokenPriceService"),
		deleteTokenPriceService: unimplemented("\(Self.self).deleteTokenPriceService")
	)

	private static func noop() -> Self {
		.init(
			getTokenPrices: { _, _ in [:] },
			getTokenPriceServices: { [] },
			addTokenPriceService: { _ in true },
			deleteTokenPriceService: { _ in true }
		)
	}
}

extension DependencyValues {
	var tokenPricesClient: TokenPricesClient {
		get { self[TokenPricesClient.self] }
		set { self[TokenPricesClient.self] = newValue }
	}
}
