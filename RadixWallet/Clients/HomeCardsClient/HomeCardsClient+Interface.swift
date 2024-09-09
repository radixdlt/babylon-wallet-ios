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

extension HomeCardsClient {
	/// An empty method to be called when the app starts, so that the client gets initialized before being used for the first time.
	/// This is necessary to monitor events that need to be delivered to Sargon before the client is used from its respective UI.
	/// Should be removed once SargonOS is integrated.
	func bootstrap() {}
}
