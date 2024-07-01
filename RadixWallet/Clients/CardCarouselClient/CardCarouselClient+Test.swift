// MARK: - CardCarouselClient + TestDependencyKey
extension CardCarouselClient: TestDependencyKey {
	public static let previewValue = Self.noop

	public static let testValue = Self(
		cards: unimplemented("\(Self.self).cards"),
		tappedCard: unimplemented("\(Self.self).tappedCard"),
		closeCard: unimplemented("\(Self.self).closeCard")
	)
}

extension CardCarouselClient {
	public static let noop = Self(
		cards: { AsyncLazySequence([]).eraseToAnyAsyncSequence() },
		tappedCard: { _ in },
		closeCard: { _ in }
	)
}
