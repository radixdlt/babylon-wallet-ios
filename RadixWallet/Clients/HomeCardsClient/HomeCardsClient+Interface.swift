// MARK: - HomeCardsClient
public struct HomeCardsClient: Sendable {
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

extension HomeCardsClient {
	public typealias Cards = @Sendable () -> AnyAsyncSequence<[HomeCard]>
	public typealias RemoveCard = @Sendable (HomeCard) -> Void
	public typealias WalletStarted = @Sendable () -> Void
	public typealias WalletCreated = @Sendable () -> Void
	public typealias DeepLinkReceived = @Sendable (String) -> Void
}

extension DependencyValues {
	public var homeCardsClient: HomeCardsClient {
		get { self[HomeCardsClient.self] }
		set { self[HomeCardsClient.self] = newValue }
	}
}
