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
		case cardTapped(CarouselCard)
		case closeTapped(CarouselCard)
	}

	public var body: some ReducerOf<Self> {
		Reduce(core)
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .didAppear:
			print("•• didAppear")
			return .none
		case let .cardTapped(card):
			state.taps += 1
			print("•• didTap \(state.taps)")
			return .none
		case let .closeTapped(card):
			guard let index = state.cards.firstIndex(where: { $0 == card }) else { return .none }
			state.cards.remove(at: index)
			return .none
		}
	}
}

// MARK: - CarouselCard
public enum CarouselCard: Hashable, Sendable {
	case threeSixtyDegrees
	case connect
	case somethingElse
}

import SwiftUI

// MARK: - CardCarousel.View
extension CardCarousel {
	public struct View: SwiftUI.View {
		private static let coordSpace: String = "CardCarousel"

		private let margin: CGFloat = .medium1
		private let spacing: CGFloat = .small1

		let store: StoreOf<CardCarousel>

		public var body: some SwiftUI.View {
			WithPerceptionTracking {
				if !store.cards.isEmpty {
					core
				}
			}
		}

		@MainActor
		private var core: some SwiftUI.View {
			GeometryReader { proxy in
				WithPerceptionTracking {
					TabView {
						ForEach(store.cards, id: \.self) { card in
							CarouselCardView(card: card) {
								store.send(.view(.cardTapped(card)))
							} closeAction: {
								store.send(.view(.closeTapped(card)), animation: .default)
							}
							.measurePosition(card, coordSpace: Self.coordSpace)
							.padding(.horizontal, 0.5 * spacing)
							.transition(.scale(scale: 0.8).combined(with: .opacity))
						}
					}
				}
				.tabViewStyle(.page(indexDisplayMode: .never))
				.coordinateSpace(name: Self.coordSpace)
				.backgroundPreferenceValue(PositionsPreferenceKey.self) { positions in
					dummyCards(positions, in: proxy.frame(in: .named(Self.coordSpace)))
				}
			}
			.padding(.horizontal, margin - 0.5 * spacing)
			.frame(height: 105)
			.onAppear {
				store.send(.view(.didAppear))
			}
			.transition(.scale(scale: 0.8).combined(with: .opacity))
		}

		@MainActor
		private func dummyCards(_ positions: [AnyHashable: CGRect], in frame: CGRect) -> some SwiftUI.View {
			WithPerceptionTracking {
				let dummyPositions = dummyPositions(positions, frame: frame, cards: store.cards)
				ForEach(dummyPositions, id: \.card) { card, pos in
					CarouselCardView.Dummy(card: card)
						.frame(width: pos.width, height: pos.height)
						.offset(x: pos.minX - margin)
				}
			}
		}

		private func dummyPositions(_ positions: [AnyHashable: CGRect], frame: CGRect, cards: [CarouselCard]) -> [(card: CarouselCard, pos: CGRect)] {
			guard let width = positions.first?.value.width else { return [] }

			let thisCard = positions.mapValues { abs($0.midX - frame.midX) }.min { $0.value < $1.value }?.key.base as? CarouselCard
			guard let thisCard, let currentIndex = cards.firstIndex(of: thisCard), let rect = positions[thisCard] else { return [] }
			var result: [(CarouselCard, CGRect)] = []
			if cards.indices.contains(currentIndex - 1) {
				result.append((cards[currentIndex - 1], rect.offsetBy(dx: -(width + spacing), dy: 0)))
			}
			if !frame.contains(rect) {
				result.append((thisCard, rect))
			}
			if cards.indices.contains(currentIndex + 1) {
				result.append((cards[currentIndex + 1], rect.offsetBy(dx: width + spacing, dy: 0)))
			}

			return result
		}
	}
}

extension CGRect {
	var center: CGPoint {
		.init(x: midX, y: midY)
	}
}

// MARK: - CarouselCardView
public struct CarouselCardView: View {
	public let card: CarouselCard
	public let action: () -> Void
	public let closeAction: () -> Void

	public var body: some View {
		Button(action: action) {
			Text("\(title)")
				.padding(.large2)
				.padding(.medium2)
				.frame(maxWidth: .infinity, alignment: .center)
				.frame(height: 105)
				.background(.app.gray3)
				.cornerRadius(.small1)
		}
		.overlay(alignment: .topTrailing) {
			CloseButton(action: closeAction)
		}
	}

	public struct Dummy: View {
		let card: CarouselCard

		public var body: some SwiftUI.View {
			CarouselCardView(card: card, action: {}, closeAction: {})
				.disabled(true)
		}
	}

	private var title: String {
		switch card {
		case .threeSixtyDegrees:
			"360 Degrees of Security"
		case .connect:
			"Link to connector"
		case .somethingElse:
			"Something Lorem Ipsum"
		}
	}

	private var message: String {
		switch card {
		case .threeSixtyDegrees:
			"Secure your Accounts and Personas with Security shields"
		case .connect:
			"Do it now"
		case .somethingElse:
			"Blabbely bla"
		}
	}
}
