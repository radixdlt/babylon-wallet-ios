// MARK: - CardCarouselClient
public struct CardCarouselClient: Sendable {
	public var cards: Cards
	public var removeCard: RemoveCard
	public var start: Start
	public var startForNewWallet: StartForNewWallet
	public var handleDeferredDeepLink: HandleDeferredDeepLink

	init(
		cards: @escaping Cards,
		removeCard: @escaping RemoveCard,
		start: @escaping Start,
		startForNewWallet: @escaping StartForNewWallet,
		handleDeferredDeepLink: @escaping HandleDeferredDeepLink
	) {
		self.cards = cards
		self.removeCard = removeCard
		self.start = start
		self.startForNewWallet = startForNewWallet
		self.handleDeferredDeepLink = handleDeferredDeepLink
	}
}

extension CardCarouselClient {
	public typealias Cards = @Sendable () -> AnyAsyncSequence<[HomeCard]>
	public typealias RemoveCard = @Sendable (HomeCard) -> Void
	public typealias Start = @Sendable () -> Void
	public typealias StartForNewWallet = @Sendable () -> Void
	public typealias HandleDeferredDeepLink = @Sendable (String) -> Void
}

extension DependencyValues {
	public var cardCarouselClient: CardCarouselClient {
		get { self[CardCarouselClient.self] }
		set { self[CardCarouselClient.self] = newValue }
	}
}
