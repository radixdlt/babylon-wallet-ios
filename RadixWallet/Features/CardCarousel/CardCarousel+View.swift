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
				GeometryReader { proxy in
					coreView
						.backgroundPreferenceValue(PositionsPreferenceKey.self) { positions in
							dummyCards(positions, in: proxy.frame(in: .named(Self.coordSpace)))
						}
				}
				.padding(.horizontal, margin - 0.5 * spacing)
				.frame(height: store.cards.isEmpty ? 0 : height)
			}
			.onAppear {
				store.send(.view(.didAppear))
			}
		}

		@MainActor
		private var coreView: some SwiftUI.View {
			WithPerceptionTracking {
				TabView {
					ForEach(store.cards) { card in
						CarouselCardView(card: card) {
							store.send(.view(.cardTapped(card)))
						} closeAction: {
							store.send(.view(.closeTapped(card.id)), animation: .default)
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
	public let card: CarouselCard
	public let action: () -> Void
	public let closeAction: () -> Void

	public var body: some View {
		ZStack(alignment: .topTrailing) {
			Button(action: action) {
				VStack(alignment: .leading, spacing: .small2) {
					HStack {
						Text(title)
							.textStyle(.body1Header)
							.minimumScaleFactor(0.8)

						if case .openURL = card.action {
							Image(.iconLinkOut)
								.foregroundStyle(.app.gray2)
						}
					}

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

			// CloseButton(action: closeAction)
			Button(action: closeAction) {
				Image(asset: AssetResource.close)
					.resizable()
					.frame(width: .medium3, height: .medium3)
					.tint(.app.gray1)
					.padding(.small2)
			}
			.frame(.small, alignment: .topTrailing)
		}
	}

	public struct Dummy: View {
		let card: CarouselCard

		public var body: some SwiftUI.View {
			CarouselCardView(card: card, action: {}, closeAction: {})
				.disabled(true)
		}
	}

	private var trailingPadding: CGFloat {
		switch card.id {
		case .rejoinRadQuest, .discoverRadix:
			95
		case .continueOnDapp:
			85
		case .useDappsOnDesktop:
			106
		}
	}

	private var title: String {
		switch card.id {
		case .rejoinRadQuest:
			L10n.HomePageCarousel.RejoinRadquest.title
		case .discoverRadix:
			L10n.HomePageCarousel.DiscoverRadix.title
		case .continueOnDapp:
			L10n.HomePageCarousel.ContinueOnDapp.title
		case .useDappsOnDesktop:
			L10n.HomePageCarousel.UseDappsOnDesktop.title
		}
	}

	private var text: String {
		switch card.id {
		case .rejoinRadQuest:
			L10n.HomePageCarousel.RejoinRadquest.text
		case .discoverRadix:
			L10n.HomePageCarousel.DiscoverRadix.text
		case .continueOnDapp:
			L10n.HomePageCarousel.ContinueOnDapp.text
		case .useDappsOnDesktop:
			L10n.HomePageCarousel.UseDappsOnDesktop.text
		}
	}

	private var background: some View {
		switch card.id {
		case .rejoinRadQuest:
			cardBackground(.gradient(.carouselBackgroundRadquest))
		case .discoverRadix:
			cardBackground(.gradient(.carouselBackgroundRadquest))
		case .continueOnDapp:
			cardBackground(.thumbnail(.dapp, .init(string: "https://assets.caviarnine.com/tokens/caviar_babylon.png")))
		case .useDappsOnDesktop:
			cardBackground(.gradient(.carouselBackgroundConnect))
		}
	}

	@ViewBuilder
	private func cardBackground(_ type: BackgroundType) -> some View {
		switch type {
		case let .thumbnail(type, url):
			Thumbnail(type, url: url, size: .smallish)
				.padding(.trailing, .medium2)
				.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
		case let .gradient(imageResource):
			Image(imageResource)
				.resizable()
				.aspectRatio(contentMode: .fill)
				.mask {
					LinearGradient(colors: [.clear, .white, .white], startPoint: .leading, endPoint: .trailing)
				}
		}
	}

	private enum BackgroundType {
		case thumbnail(Thumbnail.ContentType, URL?)
		case gradient(ImageResource)
	}
}
