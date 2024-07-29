// MARK: - HomeCardsClient + TestDependencyKey
extension HomeCardsClient: TestDependencyKey {
	public static let previewValue = Self.noop

	public static let testValue = Self(
		cards: unimplemented("\(Self.self).cards"),
		removeCard: unimplemented("\(Self.self).removeCard")
	)
}

extension HomeCardsClient {
	public static let noop = Self(
		cards: { AsyncLazySequence([]).eraseToAnyAsyncSequence() },
		removeCard: { _ in }
	)
}
