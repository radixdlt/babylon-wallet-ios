import ComposableArchitecture

// MARK: - CardCarousel
@Reducer
public struct CardCarousel: FeatureReducer, Sendable {
	@ObservableState
	public struct State: Hashable, Sendable {
		public var cards: [CarouselCard] = [.init(id: .continueOnDapp, action: .dismiss)]
	}

	public typealias Action = FeatureAction<Self>

	@CasePathable
	public enum ViewAction: Equatable, Sendable {
		case didAppear
		case cardTapped(CarouselCard)
		case closeTapped(CarouselCard.ID)
	}

	@CasePathable
	public enum InternalAction: Equatable, Sendable {
		case setCards([CarouselCard])
	}

	@Dependency(\.cardCarouselClient) var cardCarouselClient
	@Dependency(\.openURL) var openURL

	public var body: some ReducerOf<Self> {
		Reduce(core)
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .didAppear:
			return .run { send in
				do {
					for try await cards in cardCarouselClient.cards() {
						await send(.internal(.setCards(cards)))
					}
				} catch {}
			}
		case let .cardTapped(card):
			cardCarouselClient.tappedCard(card.id)
			switch card.action {
			case let .openURL(url):
				return .run { _ in
					await openURL(url)
				}
			case .dismiss:
				return .none
			}
		case let .closeTapped(id):
			cardCarouselClient.closeCard(id)
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .setCards(cards):
			state.cards = cards
			return .none
		}
	}
}
