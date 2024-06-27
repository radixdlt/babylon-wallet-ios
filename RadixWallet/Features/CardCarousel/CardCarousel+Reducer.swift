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

		private let margin: CGFloat = 3 * .medium1
		private let spacing: CGFloat = 3 * .small1

		let store: StoreOf<CardCarousel>
		@SwiftUI.State private var card: CarouselCard? = nil

		public var body: some SwiftUI.View {
			WithPerceptionTracking {
				GeometryReader { proxy in
					TabView {
						ForEach(store.cards, id: \.self) { card in
							CarouselCardView(card: card)
								.measurePosition(card, coordSpace: Self.coordSpace)
								.overlay(alignment: .topTrailing) {
									CloseButton {
										store.send(.view(.closeTapped(card)), animation: .default)
									}
								}
								.padding(.horizontal, 0.5 * spacing)
								.transition(.scale(scale: 0.8).combined(with: .opacity))
								.border(.red)
						}
					}
					.tabViewStyle(.page(indexDisplayMode: .never))
					.coordinateSpace(name: Self.coordSpace)
					.border(.black)
					.overlayPreferenceValue(PositionsPreferenceKey.self) { positions in
						let frame = proxy.frame(in: .named(Self.coordSpace))
						let neighbours = neighbours(positions, frame: frame, cards: store.cards)
						ForEach(neighbours, id: \.card) { _, pos in
							Rectangle()
								.stroke(.red, lineWidth: 4)
								.frame(width: pos.width, height: pos.height)
								.offset(x: pos.minX - margin)
						}

//						Rectangle()
//							.stroke(.orange, lineWidth: 5)
//							.frame(width: frame.width, height: frame.height)
//							.offset(x: frame.minX - margin)
					}
				}
				.padding(.horizontal, margin - 0.5 * spacing)
				.frame(height: 105)
			}
			.onAppear {
				store.send(.view(.didAppear))
			}
		}

		private func neighbours(_ positions: [AnyHashable: CGRect], frame: CGRect, cards: [CarouselCard]) -> [(card: CarouselCard, pos: CGRect)] {
			guard let width = positions.first?.value.width else { return [] }

			print("•• POSITIONS in \(frame)")
			for (x, y) in positions {
				print("•• \(x): \(Int(y.minX.rounded())) - \(Int(y.maxX.rounded()))")
			}

			let current = positions.mapValues { abs($0.midX - frame.midX) }.min { $0.value < $1.value }
			guard let current, let card = current.key.base as? CarouselCard else { return [] }
			guard let currentIndex = cards.firstIndex(of: card), let rect = positions[card] else { return [] }
			var result: [(CarouselCard, CGRect)] = []
			if cards.indices.contains(currentIndex - 1) {
				result.append((cards[currentIndex - 1], rect.offsetBy(dx: -(width + spacing), dy: 0)))
			}
			let nextRect = rect.offsetBy(dx: width + spacing, dy: 0)

			if cards.indices.contains(currentIndex + 1) {
				result.append((cards[currentIndex + 1], nextRect))
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
	let card: CarouselCard

	public var body: some SwiftUI.View {
		Text("\(title)")
			.padding(.large2)
			.padding(.medium2)
			.frame(maxWidth: .infinity, alignment: .center)
			.frame(height: 105)
			.background(.app.gray3)
			.cornerRadius(.small1)
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
