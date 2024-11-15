import Foundation
import SwiftUI

// MARK: - CardCarousel.View
extension CardCarousel {
	struct View: SwiftUI.View {
		let store: StoreOf<CardCarousel>

		private let margin: CGFloat = .medium1
		private let spacing: CGFloat = .small1 * 0.5
		@ScaledMetric private var height: CGFloat = 105
		@SwiftUI.State private var selectedCardIndex = 0

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				VStack(spacing: .small2) {
					coreView
						.frame(height: store.cards.isEmpty ? .small2 : height)

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
				}
			}
			.tabViewStyle(.page(indexDisplayMode: .never))
		}

		@ViewBuilder
		private var positionIndicator: some SwiftUI.View {
			if store.cards.count > 1 {
				HStack(spacing: spacing) {
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
struct CarouselCardView: View {
	let card: HomeCard
	let action: () -> Void
	let closeAction: () -> Void

	var body: some View {
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

			CloseButton(kind: .homeCard, action: closeAction)
		}
	}

	private var trailingPadding: CGFloat {
		switch card {
		case .continueRadQuest, .startRadQuest, .discoverRadixDapps:
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
		case .discoverRadixDapps:
			L10n.HomePageCarousel.DiscoverRadixDapps.title
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
		case .discoverRadixDapps:
			L10n.HomePageCarousel.DiscoverRadixDapps.text
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
		case .discoverRadixDapps:
			cardBackground(.gradient(.carouselBackgroundEcosystem))
		}
	}

	private var showLinkIcon: Bool {
		switch card {
		case .startRadQuest, .discoverRadixDapps:
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
