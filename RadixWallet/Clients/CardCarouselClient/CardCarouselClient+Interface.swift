// MARK: - CardCarouselClient
public struct CardCarouselClient: Sendable {
	public var cards: Cards
	public var closeCard: CloseCard

	init(
		cards: @escaping Cards,
		closeCard: @escaping CloseCard
	) {
		self.cards = cards
		self.closeCard = closeCard
	}
}

// MARK: - CarouselCard
public enum CarouselCard: Hashable, Sendable {
	case threeSixtyDegrees
	case connect
	case somethingElse
}

extension CardCarouselClient {
	public typealias Cards = @Sendable () -> AnyAsyncSequence<[CarouselCard]>
	public typealias CloseCard = @Sendable (CarouselCard) -> Void
}

extension DependencyValues {
	public var cardCarouselClient: CardCarouselClient {
		get { self[CardCarouselClient.self] }
		set { self[CardCarouselClient.self] = newValue }
	}
}
