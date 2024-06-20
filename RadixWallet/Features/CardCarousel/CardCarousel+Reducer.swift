import ComposableArchitecture

// MARK: - CardCarousel
@Reducer
public struct CardCarousel: FeatureReducer {
	@ObservableState
	public struct State: Hashable, Sendable {
		public var cards: [CarouselCard]
		public var taps: Int = 0
	}

	public typealias Action = FeatureAction<Self>

	@CasePathable
	public enum ViewAction: Equatable, Sendable {
		case didAppear
		case didTap(CarouselCard)
	}

	public var body: some ReducerOf<Self> {
		Reduce(core)
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .didAppear:
			print("•• didAppear")
			return .none
		case let .didTap(card):
			state.taps += 1
			print("•• didTap \(state.taps)")
			return .none
		}
	}
}

// MARK: - CarouselCard
public enum CarouselCard: Hashable, Sendable {
	case threeSixtyDegrees
	case connect
}

import SwiftUI

// MARK: - CardCarousel.View
extension CardCarousel {
	public struct View: SwiftUI.View {
		let store: StoreOf<CardCarousel>

		public var body: some SwiftUI.View {
			WithPerceptionTracking {
				VStack {
					Text("\(store.taps) taps")
					ForEachStatic(store.cards) { card in
						Button {
							store.send(.view(.didTap(card)))
						} label: {
							Text("\(card.title)")
						}
					}
				}
			}
			.border(.red)
			.onAppear {
				store.send(.view(.didAppear))
			}
		}
	}
}

extension CarouselCard {
	public var title: String {
		switch self {
		case .threeSixtyDegrees:
			"360 Degrees of Security"
		case .connect:
			"Link to connector"
		}
	}

	public var body: String {
		switch self {
		case .threeSixtyDegrees:
			"Secure your Accounts and Personas with Security shields"
		case .connect:
			"Do it now"
		}
	}

//		public var button: String
//		public var image: ImageAsset
}
