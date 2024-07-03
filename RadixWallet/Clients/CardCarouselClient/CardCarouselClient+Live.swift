import ComposableArchitecture

extension CardCarouselClient: DependencyKey {
	public static let liveValue: Self = {
		// Delete if not needed
		@Dependency(\.userDefaults) var userDefaults

		// Just for testing
		let allCards: [CarouselCard] = [
			.init(id: .rejoinRadQuest, action: .dismiss),
			.init(id: .discoverRadix, action: .openURL(.init(string: "https://www.radixdlt.com/blog")!)),
			.init(id: .continueOnDapp, action: .dismiss),
			.init(id: .useDappsOnDesktop, action: .dismiss),
		]

		let cardSubject = AsyncCurrentValueSubject(allCards)

		@Sendable
		func closeCard(id: CarouselCard.ID) {
			guard let index = cardSubject.value.map(\.id).firstIndex(of: id) else { return }
			cardSubject.value.remove(at: index)
		}

		return Self(
			cards: {
				cardSubject.eraseToAnyAsyncSequence()
			},
			tappedCard: { id in
				closeCard(id: id)
				// TODO: Store the fact that we have tapped this card somewhere
			},
			closeCard: { id in
				closeCard(id: id)
				// TODO: Store the fact that we have closed this card somewhere
			}
		)
	}()
}
