import ComposableArchitecture

// MARK: - CardCarouselClient + DependencyKey
extension CardCarouselClient: DependencyKey {
	public static let liveValue: Self = {
		let observer = HomeCardsObserver()

		// We are hardcoding to `.mainnet` because the cards are currently gateway agnostic. In the future, when Profile is integrated into Sargon, it will be Sargon
		// observing the current gateway and defining the networkId to use.
		let manager = HomeCardsManager(networkAntenna: URLSession.shared, networkId: .mainnet, cardsStorage: HomeCardsStorage(), observer: observer)

		return Self(
			cards: {
				observer.subject.eraseToAnyAsyncSequence()
			},
			removeCard: { card in
				Task {
					try? await manager.cardDismissed(card: card)
				}
			},
			walletStarted: {
				Task {
					try? await manager.walletStarted()
				}
			},
			walletCreated: {
				Task {
					try? await manager.walletCreated()
				}
			},
			deepLinkReceived: { value in
				Task {
					try? await manager.deepLinkReceived(encodedValue: value)
				}
			}
		)
	}()
}

// MARK: - HomeCardsManager + Sendable
extension HomeCardsManager: @unchecked Sendable {}

// MARK: - HomeCardsStorage
private final class HomeCardsStorage: Sargon.HomeCardsStorage {
	@Dependency(\.userDefaults) var userDefaults

	func saveCards(encodedCards: Data) async throws {
		userDefaults.setHomeCards(encodedCards)
	}

	func loadCards() async throws -> Data? {
		userDefaults.getHomeCards()
	}
}

// MARK: - HomeCardsObserver
private final class HomeCardsObserver: Sargon.HomeCardsObserver, Sendable {
	let subject: AsyncCurrentValueSubject<[HomeCard]> = .init([])

	func handleCardsUpdate(cards: [HomeCard]) {
		subject.send(cards)
	}
}
