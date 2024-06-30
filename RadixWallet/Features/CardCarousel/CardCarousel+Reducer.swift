import ComposableArchitecture

// MARK: - CardCarousel
@Reducer
public struct CardCarousel: FeatureReducer, Sendable {
	@ObservableState
	public struct State: Hashable, Sendable {
		public var cards: [CarouselCard] = [.continueOnDapp]
	}

	public typealias Action = FeatureAction<Self>

	@CasePathable
	public enum ViewAction: Equatable, Sendable {
		case didAppear
		case cardTapped(CarouselCard)
		case closeTapped(CarouselCard)
	}

	@CasePathable
	public enum InternalAction: Equatable, Sendable {
		case setCards([CarouselCard])
	}

	@Dependency(\.cardCarouselClient) var cardCarouselClient

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
			switch card {
			case .rejoinRadQuest:
				break
			case .discoverRadix:
				break
			case .continueOnDapp:
				break
			case .useDappsOnDesktop:
				break
			case .threeSixtyDegrees:
				break
			}
			cardCarouselClient.tappedCard(card)
			return .none
		case let .closeTapped(card):
			cardCarouselClient.closeCard(card)
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
