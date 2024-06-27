import ComposableArchitecture

extension CardCarouselClient: DependencyKey {
	public static let liveValue: Self = {
		let cardSubject = AsyncCurrentValueSubject<[CarouselCard]>([.threeSixtyDegrees, .connect, .somethingElse])

		@Dependency(\.errorQueue) var errorQueue
		@Dependency(\.appPreferencesClient) var appPreferencesClient
		@Dependency(\.cacheClient) var cacheClient
		@Dependency(\.radixConnectClient) var radixConnectClient
		@Dependency(\.userDefaults) var userDefaults

		return Self(
			cards: {
				cardSubject.eraseToAnyAsyncSequence()
			},
			closeCard: { card in
				guard let index = cardSubject.value.firstIndex(of: card) else { return }
				cardSubject.value.remove(at: index)
			}
		)
	}()
}
