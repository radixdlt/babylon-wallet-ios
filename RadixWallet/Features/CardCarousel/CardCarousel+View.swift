import Foundation
import SwiftUI

// MARK: - CardCarousel.View
extension CardCarousel {
	public struct View: SwiftUI.View {
		public let store: StoreOf<CardCarousel>

		private let margin: CGFloat = .medium1
		private let spacing: CGFloat = .small1 * 0.5
		@ScaledMetric private var height: CGFloat = 105
		@SwiftUI.State private var selectedCardIndex = 0

		public var body: some SwiftUI.View {
			WithPerceptionTracking {
				VStack(spacing: .small2) {
					coreView
						.frame(height: store.cards.isEmpty ? 0 : height)

					positionIndicator
				}
			}
			.task {
				store.send(.view(.task))
			}
		}

		@MainActor
		private var coreView: some SwiftUI.View {
			TabView(selection: $selectedCardIndex) {
				ForEach(Array(store.cards.enumerated()), id: \.element) { index, card in
					CarouselCardView(card: card) {
						store.send(.view(.cardTapped(card)))
					} closeAction: {
						store.send(.view(.closeTapped(card)), animation: .default)
					}
					.tag(index)
					.padding(.horizontal, margin - spacing)
					.transition(.scale(scale: 0.8).combined(with: .opacity))
				}
			}
			.tabViewStyle(.page(indexDisplayMode: .never))
			.animation(.default, value: store.cards)
		}

		private var positionIndicator: some SwiftUI.View {
			HStack(spacing: spacing) {
				if store.cards.count > 1 {
					ForEach(0 ..< store.cards.count, id: \.self) { index in
						let isSelected = selectedCardIndex == index
						Capsule()
							.fill(isSelected ? .app.gray2 : .app.gray4)
							.frame(isSelected ? spacing : .small3)
					}
				}
			}
		}
	}
}

// MARK: - CarouselCardView
public struct CarouselCardView: View {
	public let card: HomeCard
	public let action: () -> Void
	public let closeAction: () -> Void

	public var body: some View {
		ZStack(alignment: .topTrailing) {
			Button(action: action) {
				VStack(alignment: .leading, spacing: .small2) {
					HStack(spacing: .small3 * 0.5) {
						Text(title)
							.textStyle(.body1Header)
							.minimumScaleFactor(0.8)

						if showLinkIcon {
							Image(.iconLinkOut)
								.resizable()
								.frame(.icon)
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

			Button(action: closeAction) {
				Image(asset: AssetResource.close)
					.resizable()
					.frame(width: .medium3, height: .medium3)
					.tint(.app.gray2)
					.padding(.small2)
			}
			.frame(.small, alignment: .topTrailing)
		}
	}

	private var trailingPadding: CGFloat {
		switch card {
		case .continueRadQuest, .startRadQuest:
			95
		case .dapp:
			85
		case .connector:
			106
		}
	}

	private var title: String {
		switch card {
		case .continueRadQuest:
			L10n.HomePageCarousel.RejoinRadquest.title
		case .startRadQuest:
			L10n.HomePageCarousel.DiscoverRadix.title
		case .dapp:
			L10n.HomePageCarousel.ContinueOnDapp.title
		case .connector:
			L10n.HomePageCarousel.UseDappsOnDesktop.title
		}
	}

	private var text: String {
		switch card {
		case .continueRadQuest:
			L10n.HomePageCarousel.RejoinRadquest.text
		case .startRadQuest:
			L10n.HomePageCarousel.DiscoverRadix.text
		case .dapp:
			L10n.HomePageCarousel.ContinueOnDapp.text
		case .connector:
			L10n.HomePageCarousel.UseDappsOnDesktop.text
		}
	}

	private var background: some View {
		switch card {
		case .continueRadQuest:
			cardBackground(.gradient(.carouselBackgroundRadquest))
		case .startRadQuest:
			cardBackground(.gradient(.carouselBackgroundRadquest))
		case let .dapp(url):
			cardBackground(.thumbnail(.dapp, url))
		case .connector:
			cardBackground(.gradient(.carouselBackgroundConnect))
		}
	}

	private var showLinkIcon: Bool {
		switch card {
		case .startRadQuest:
			true
		case .continueRadQuest, .dapp, .connector:
			false
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
