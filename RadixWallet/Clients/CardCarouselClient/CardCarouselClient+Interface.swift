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
public struct CarouselCard: Hashable, Sendable, Identifiable {
	public let id: CardID
	public let action: Action

	public enum CardID: Sendable {
		case rejoinRadQuest
		case discoverRadix
		case continueOnDapp
		case useDappsOnDesktop
	}

	public enum Action: Hashable, Sendable {
		case openURL(URL)
		case dismiss
	}
}

extension CardCarouselClient {
	public typealias Cards = @Sendable () -> AnyAsyncSequence<[CarouselCard]>
	public typealias TappedCard = @Sendable (CarouselCard.ID) -> Void
	public typealias CloseCard = @Sendable (CarouselCard.ID) -> Void
}

extension DependencyValues {
	public var cardCarouselClient: CardCarouselClient {
		get { self[CardCarouselClient.self] }
		set { self[CardCarouselClient.self] = newValue }
	}
}
