// MARK: - HomeCardsClient
struct HomeCardsClient: Sendable {
	var cards: Cards
	var removeCard: RemoveCard
	var bootstrap: Bootstrap

	init(
		cards: @escaping Cards,
		removeCard: @escaping RemoveCard,
		bootstrap: @escaping Bootstrap
	) {
		self.cards = cards
		self.removeCard = removeCard
		self.bootstrap = bootstrap
	}
}

extension HomeCardsClient {
	typealias Cards = @Sendable () -> AnyAsyncSequence<[HomeCard]>
	typealias RemoveCard = @Sendable (HomeCard) -> Void
	typealias Bootstrap = @Sendable () -> Void
}

extension DependencyValues {
	var homeCardsClient: HomeCardsClient {
		get { self[HomeCardsClient.self] }
		set { self[HomeCardsClient.self] = newValue }
	}
}
