import ComposableArchitecture

// MARK: - CardCarouselClient + DependencyKey
extension CardCarouselClient: DependencyKey {
	public static let liveValue: Self = {
		let observer = HomeCardsObserver()
		// TODO: where to get networkId
		let manager = HomeCardsManager(networkAntenna: URLSession.shared, networkId: .mainnet, cardsStorage: HomeCardsStorage(), observer: observer)

		return Self(
			cards: {
				observer.subject.eraseToAnyAsyncSequence()
			},
			removeCard: { card in
				Task {
					try? await manager.removeCard(card: card)
				}
			},
			start: {
				Task {
					try? await manager.initCards()
				}
			},
			startForNewWallet: {
				Task {
					try? await manager.initCardsForNewWallet()
				}
			},
			handleDeferredDeepLink: { value in
				Task {
					try? await manager.handleDeferredDeepLink(encodedValue: value)
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
