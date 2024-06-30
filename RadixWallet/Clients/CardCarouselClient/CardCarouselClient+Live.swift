import ComposableArchitecture

extension CardCarouselClient: DependencyKey {
	public static let liveValue: Self = {
		// Just delete the ones that are not needed
		@Dependency(\.errorQueue) var errorQueue
		@Dependency(\.appPreferencesClient) var appPreferencesClient
		@Dependency(\.cacheClient) var cacheClient
		@Dependency(\.radixConnectClient) var radixConnectClient
		@Dependency(\.userDefaults) var userDefaults

		let allCards: [CarouselCard] = [.rejoinRadQuest, .discoverRadix, .continueOnDapp, .useDappsOnDesktop, .threeSixtyDegrees]
		let cardSubject = AsyncCurrentValueSubject(allCards)

		return Self(
			cards: {
				cardSubject.eraseToAnyAsyncSequence()
			},
			tappedCard: { _ in
				// TODO: Store the fact that we have tapped this card somewhere
			},
			closeCard: { card in
				guard let index = cardSubject.value.firstIndex(of: card) else { return }
				cardSubject.value.remove(at: index)
				// TODO: Store the fact that we have closed this card somewhere
			}
		)
	}()
}
