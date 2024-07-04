// MARK: - CardCarouselClient + TestDependencyKey
extension CardCarouselClient: TestDependencyKey {
	public static let previewValue = Self.noop

	public static let testValue = Self(
		cards: unimplemented("\(Self.self).cards"),
		removeCard: unimplemented("\(Self.self).removeCard"),
		walletStarted: unimplemented("\(Self.self).walletStarted"),
		walletCreated: unimplemented("\(Self.self).walletCreated"),
		deepLinkReceived: unimplemented("\(Self.self).deepLinkReceived")
	)
}

extension CardCarouselClient {
	public static let noop = Self(
		cards: { AsyncLazySequence([]).eraseToAnyAsyncSequence() },
		removeCard: { _ in },
		walletStarted: {},
		walletCreated: {},
		deepLinkReceived: { _ in }
	)
}
