import Foundation
import SwiftUI

// MARK: - CardCarousel.View
extension CardCarousel {
	public struct View: SwiftUI.View {
		public let store: StoreOf<CardCarousel>

		private static let coordSpace: String = "CardCarousel"

		private let margin: CGFloat = .medium1
		private let spacing: CGFloat = .small1
		@ScaledMetric private var height: CGFloat = 105

		public var body: some SwiftUI.View {
			WithPerceptionTracking {
				if !store.cards.isEmpty {
					GeometryReader { proxy in
						coreView
							.backgroundPreferenceValue(PositionsPreferenceKey.self) { positions in
								dummyCards(positions, in: proxy.frame(in: .named(Self.coordSpace)))
							}
					}
					.padding(.horizontal, margin - 0.5 * spacing)
					.frame(height: height)
					.transition(.scale(scale: 0.8).combined(with: .opacity))
				}
			}
			.onAppear {
				store.send(.view(.didAppear))
			}
		}

		@MainActor
		private var coreView: some SwiftUI.View {
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
				.tabViewStyle(.page(indexDisplayMode: .never))
				.animation(.default, value: store.cards)
			}
			.coordinateSpace(name: Self.coordSpace)
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
				.animation(nil, value: store.cards)
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

// MARK: - CarouselCardView
public struct CarouselCardView: View {
	private let trailingPadding: CGFloat = 115

	public let card: CarouselCard
	public let action: () -> Void
	public let closeAction: () -> Void

	public var body: some View {
		ZStack(alignment: .topTrailing) {
			Button(action: action) {
				VStack(alignment: .leading, spacing: .small2) {
					Text(title)
						.textStyle(.body1Header)
					Text(text)
						.lineSpacing(-20)
						.lineLimit(nil)
						.minimumScaleFactor(0.8)
						.textStyle(.body2Regular)
				}
				.multilineTextAlignment(.leading)
				.foregroundStyle(.app.gray1)
				.padding([.top, .leading], .medium2)
				.padding(.trailing, trailingPadding)
				.padding(.bottom, .small1)
				.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
				.background(alignment: .trailing) {
					background
				}
				.background(.app.gray5)
				.cornerRadius(.small1)
			}

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
		case .rejoinRadQuest:
			L10n.HomePageCarousel.RejoinRadquest.title
		case .discoverRadix:
			L10n.HomePageCarousel.DiscoverRadix.title
		case .continueOnDapp:
			L10n.HomePageCarousel.ContinueOnDapp.title
		case .useDappsOnDesktop:
			L10n.HomePageCarousel.UseDappsOnDesktop.title
		case .threeSixtyDegrees:
			L10n.HomePageCarousel.ThreesixtyDegrees.title
		}
	}

	private var text: String {
		switch card {
		case .rejoinRadQuest:
			L10n.HomePageCarousel.RejoinRadquest.text
		case .discoverRadix:
			L10n.HomePageCarousel.DiscoverRadix.text
		case .continueOnDapp:
			L10n.HomePageCarousel.ContinueOnDapp.text
		case .useDappsOnDesktop:
			L10n.HomePageCarousel.UseDappsOnDesktop.text
		case .threeSixtyDegrees:
			L10n.HomePageCarousel.ThreesixtyDegrees.text
		}
	}

	private var background: some View {
		switch card {
		case .rejoinRadQuest:
			cardBackground(.carouselBackgroundRadquest, type: .gradient)
		case .discoverRadix:
			cardBackground(.carouselBackgroundRadquest, type: .gradient)
		case .continueOnDapp:
			cardBackground(.carouselIconContinueOnDapp, type: .icon)
		case .useDappsOnDesktop:
			cardBackground(.carouselBackgroundConnect, type: .gradient)
		case .threeSixtyDegrees:
			cardBackground(.carouselFullBackground360, type: .full)
		}
	}

	@ViewBuilder
	private func cardBackground(_ imageResource: ImageResource, type: BackgroundType) -> some View {
		switch type {
		case .icon:
			Image(imageResource)
				.padding(.trailing, .medium2)
				.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
		case .gradient:
			Image(imageResource)
				.resizable()
				.aspectRatio(contentMode: .fill)
				.mask {
					LinearGradient(colors: [.clear, .white, .white], startPoint: .leading, endPoint: .trailing)
				}
		case .full:
			Image(imageResource)
				.resizable()
				.aspectRatio(contentMode: .fill)
		}
	}

	private enum BackgroundType {
		case icon
		case gradient
		case full
	}
}
