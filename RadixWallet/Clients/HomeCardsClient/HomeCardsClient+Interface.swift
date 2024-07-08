// MARK: - HomeCardsClient
public struct HomeCardsClient: Sendable {
	public var cards: Cards
	public var removeCard: RemoveCard

	init(
		cards: @escaping Cards,
		removeCard: @escaping RemoveCard
	) {
		self.cards = cards
		self.removeCard = removeCard
	}
}

extension HomeCardsClient {
	public typealias Cards = @Sendable () -> AnyAsyncSequence<[HomeCard]>
	public typealias RemoveCard = @Sendable (HomeCard) -> Void
}

extension DependencyValues {
	public var homeCardsClient: HomeCardsClient {
		get { self[HomeCardsClient.self] }
		set { self[HomeCardsClient.self] = newValue }
	}
}
