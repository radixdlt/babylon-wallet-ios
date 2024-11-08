// MARK: - HomeCardsClient + TestDependencyKey
extension HomeCardsClient: TestDependencyKey {
	static let previewValue = Self.noop

	static let testValue = Self(
		cards: unimplemented("\(Self.self).cards"),
		removeCard: unimplemented("\(Self.self).removeCard")
	)
}

extension HomeCardsClient {
	static let noop = Self(
		cards: { AsyncLazySequence([]).eraseToAnyAsyncSequence() },
		removeCard: { _ in }
	)
}
