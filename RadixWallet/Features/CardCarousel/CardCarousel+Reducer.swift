import ComposableArchitecture

// MARK: - CardCarousel
@Reducer
public struct CardCarousel: FeatureReducer, Sendable {
	@ObservableState
	public struct State: Hashable, Sendable {
		public var cards: [HomeCard] = []
	}

	public typealias Action = FeatureAction<Self>

	@CasePathable
	public enum ViewAction: Equatable, Sendable {
		case didAppear
		case cardTapped(HomeCard)
		case closeTapped(HomeCard)
	}

	@CasePathable
	public enum InternalAction: Equatable, Sendable {
		case setCards([HomeCard])
	}

	@Dependency(\.cardCarouselClient) var cardCarouselClient
	@Dependency(\.openURL) var openURL

	public var body: some ReducerOf<Self> {
		Reduce(core)
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .didAppear:
			.run { send in
				do {
					for try await cards in cardCarouselClient.cards() {
						await send(.internal(.setCards(cards)))
					}
				} catch {}
			}
		case let .cardTapped(card):
			cardTappedEffect(card)
				.merge(with: removeCardEffect(card))
		case let .closeTapped(card):
			removeCardEffect(card)
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .setCards(cards):
			state.cards = cards
			return .none
		}
	}

	private func removeCardEffect(_ card: HomeCard) -> Effect<Action> {
		cardCarouselClient.removeCard(card)
		return .none
	}

	private func cardTappedEffect(_ card: HomeCard) -> Effect<Action> {
		switch card {
		case .continueRadQuest, .dapp:
			.none
		case .startRadQuest:
			.run { _ in
				// TODO: Define RadQuest URL
				await openURL(.init(string: "https://radixdlt.com")!)
			}
		case .connector:
			// TODO: Ask delegate to open link connector view
			.none
		}
	}
}
