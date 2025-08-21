import ComposableArchitecture

// MARK: - HomeCardsClient + DependencyKey
extension HomeCardsClient: DependencyKey {
	static let liveValue: Self = {
		@Dependency(\.appEventsClient) var appEventsClient

		let observer = HomeCardsObserver()

		// We are hardcoding to `.mainnet` because the cards are currently gateway agnostic. In the future, when Profile is integrated into Sargon, it will be Sargon
		// observing the current gateway and defining the networkId to use.
		let manager = HomeCardsManager(networkingDriver: URLSession.shared, networkId: .mainnet, cardsStorage: HomeCardsStorage(), observer: observer)

		Task {
			for try await event in appEventsClient.events() {
				guard !Task.isCancelled else { return }
				await handle(event: event)
			}
		}

		@Sendable
		func handle(event: AppEvent) async {
			switch event {
			case .appStarted:
				try? await manager.bootstrap()
			case .walletCreated:
				try? await manager.walletCreated()
			case .walletRestored:
				try? await manager.walletRestored()
			case let .deferredDeepLinkReceived(value):
				try? await manager.deferredDeepLinkReceived(encodedValue: value)
			case .walletDidReset:
				try? await manager.walletReset()
			}
		}

		return Self(
			cards: {
				observer.subject.eraseToAnyAsyncSequence()
			},
			removeCard: { card in
				Task {
					try? await manager.cardDismissed(card: card)
				}
			}
		)
	}()
}

// MARK: - HomeCardsManager + @unchecked @retroactive Sendable
extension HomeCardsManager: @unchecked @retroactive Sendable {}

// MARK: - HomeCardsStorage
private final class HomeCardsStorage: Sargon.HomeCardsStorage {
	private let userDefaults = UserDefaults.Dependency.radix

	func saveCards(encodedCards: Data) async throws {
		userDefaults.setHomeCards(encodedCards)
	}

	func loadCards() async throws -> Data? {
		userDefaults.getHomeCards()
	}

	func saveDismissedCards(encodedCards: Data) async throws {
		userDefaults.setDismissedHomeCards(encodedCards)
	}

	func loadDismissedCards() async throws -> SargonUniFFI.BagOfBytes? {
		userDefaults.getDismissedHomeCards()
	}
}

// MARK: - HomeCardsObserver
private final class HomeCardsObserver: Sargon.HomeCardsObserver, Sendable {
	let subject: AsyncCurrentValueSubject<[HomeCard]> = .init([])

	func handleCardsUpdate(cards: [HomeCard]) {
		subject.send(cards)
	}
}
