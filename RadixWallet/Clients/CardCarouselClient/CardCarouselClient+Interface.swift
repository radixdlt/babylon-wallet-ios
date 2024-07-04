// MARK: - CardCarouselClient
public struct CardCarouselClient: Sendable {
	public var cards: Cards
	public var removeCard: RemoveCard
	public var walletStarted: WalletStarted
	public var walletCreated: WalletCreated
	public var deepLinkReceived: DeepLinkReceived

	init(
		cards: @escaping Cards,
		removeCard: @escaping RemoveCard,
		walletStarted: @escaping WalletStarted,
		walletCreated: @escaping WalletCreated,
		deepLinkReceived: @escaping DeepLinkReceived
	) {
		self.cards = cards
		self.removeCard = removeCard
		self.walletStarted = walletStarted
		self.walletCreated = walletCreated
		self.deepLinkReceived = deepLinkReceived
	}
}

extension CardCarouselClient {
	public typealias Cards = @Sendable () -> AnyAsyncSequence<[HomeCard]>
	public typealias RemoveCard = @Sendable (HomeCard) -> Void
	public typealias WalletStarted = @Sendable () -> Void
	public typealias WalletCreated = @Sendable () -> Void
	public typealias DeepLinkReceived = @Sendable (String) -> Void
}

extension DependencyValues {
	public var cardCarouselClient: CardCarouselClient {
		get { self[CardCarouselClient.self] }
		set { self[CardCarouselClient.self] = newValue }
	}
}
