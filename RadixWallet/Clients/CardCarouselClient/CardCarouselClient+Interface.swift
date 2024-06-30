// MARK: - CardCarouselClient
public struct CardCarouselClient: Sendable {
	public var cards: Cards
	public var tappedCard: TappedCard
	public var closeCard: CloseCard

	init(
		cards: @escaping Cards,
		tappedCard: @escaping TappedCard,
		closeCard: @escaping CloseCard
	) {
		self.cards = cards
		self.tappedCard = tappedCard
		self.closeCard = closeCard
	}
}

// MARK: - CarouselCard
public enum CarouselCard: Hashable, Sendable {
	case rejoinRadQuest
	case discoverRadix
	case continueOnDapp
	case useDappsOnDesktop
	case threeSixtyDegrees
}

extension CardCarouselClient {
	public typealias Cards = @Sendable () -> AnyAsyncSequence<[CarouselCard]>
	public typealias TappedCard = @Sendable (CarouselCard) -> Void
	public typealias CloseCard = @Sendable (CarouselCard) -> Void
}

extension DependencyValues {
	public var cardCarouselClient: CardCarouselClient {
		get { self[CardCarouselClient.self] }
		set { self[CardCarouselClient.self] = newValue }
	}
}
