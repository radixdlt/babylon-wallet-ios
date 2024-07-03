// MARK: - CardCarouselClient + TestDependencyKey
extension CardCarouselClient: TestDependencyKey {
	public static let previewValue = Self.noop

	public static let testValue = Self(
		cards: unimplemented("\(Self.self).cards"),
		removeCard: unimplemented("\(Self.self).removeCard"),
		start: unimplemented("\(Self.self).start"),
		startForNewWallet: unimplemented("\(Self.self).startForNewWallet"),
		handleDeferredDeepLink: unimplemented("\(Self.self).handleDeferredDeepLink")
	)
}

extension CardCarouselClient {
	public static let noop = Self(
		cards: { AsyncLazySequence([]).eraseToAnyAsyncSequence() },
		removeCard: { _ in },
		start: {},
		startForNewWallet: {},
		handleDeferredDeepLink: { _ in }
	)
}
