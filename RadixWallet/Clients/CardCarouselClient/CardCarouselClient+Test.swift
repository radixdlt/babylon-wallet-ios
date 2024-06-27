// MARK: - CardCarouselClient + TestDependencyKey
extension CardCarouselClient: TestDependencyKey {
	public static let previewValue = Self.noop

	public static let testValue = Self(
		cards: unimplemented("\(Self.self).cards"),
		closeCard: unimplemented("\(Self.self).closeCard")
	)
}

extension CardCarouselClient {
	public static let noop = Self(
		cards: { AsyncLazySequence([]).eraseToAnyAsyncSequence() },
		closeCard: { _ in }
	)
}
