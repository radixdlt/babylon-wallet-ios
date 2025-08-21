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
							.fill(isSelected ? .iconSecondary : .iconTertiary)
							.frame(isSelected ? spacing : .small3)
					}
				}
			}
		}
	}
}

extension View {
	public func gradientForeground(colors: [Color]) -> some View {
		self.overlay(
			LinearGradient(
				colors: colors,
				startPoint: .topLeading,
				endPoint: .bottomTrailing
			)
		)
		.mask(self)
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
						if card == .joinRadixRewards {
							Text(title)
								.textStyle(.body1Header)
								.minimumScaleFactor(0.8)
								.gradientForeground(colors: [Color(hex: "FF43CA"), Color(hex: "20E4FF"), Color(hex: "21FFBE")])
						} else {
							Text(title)
								.textStyle(.body1Header)
								.minimumScaleFactor(0.8)
						}

						if showLinkIcon {
							Image(.iconLinkOut)
								.resizable()
								.frame(.icon)
								.foregroundStyle(card == .joinRadixRewards ? .white : .iconPrimary)
						}
					}

					Text(text)
						.lineSpacing(-20)
						.lineLimit(nil)
						.minimumScaleFactor(0.8)
						.textStyle(.body2Regular)
				}
				.multilineTextAlignment(.leading)
				.foregroundStyle(card == .joinRadixRewards ? .white : Color.primaryText)
				.padding([.top, .leading], .medium2)
				.padding(.trailing, trailingPadding)
				.padding(.bottom, .small1)
				.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
				.background(alignment: .trailing) {
					background
				}
				.background(.secondaryBackground)
				.cornerRadius(.small1)
			}
			Button(action: action) {
				Image(.close)
					.resizable()
					.frame(.medium3)
					.foregroundColor(nil)
					.tint(card == .joinRadixRewards ? .white : .iconPrimary)
					.padding(.small2)
			}
			.frame(.small, alignment: .topTrailing)
		}
	}

	private var trailingPadding: CGFloat {
		switch card {
		case .continueRadQuest, .startRadQuest:
			95
		case .dapp, .joinRadixRewards:
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
		case .joinRadixRewards:
			L10n.HomePageCarousel.JoinRadixRewards.title
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
		case .joinRadixRewards:
			L10n.HomePageCarousel.JoinRadixRewards.text
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
		case .joinRadixRewards:
			cardBackground(.gradient(.rewards))
		case .connector:
			cardBackground(.gradient(.carouselBackgroundConnect))
		}
	}

	private var showLinkIcon: Bool {
		switch card {
		case .startRadQuest, .joinRadixRewards:
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
			if card == .joinRadixRewards {
				Image(imageResource)
					.resizable()
					.aspectRatio(contentMode: .fill)
			} else {
				Image(imageResource)
					.resizable()
					.aspectRatio(contentMode: .fill)
					.mask {
						LinearGradient(colors: [.clear, Color.primaryBackground, Color.primaryBackground], startPoint: .leading, endPoint: .trailing)
					}
			}
		}
	}

	private enum BackgroundType {
		case thumbnail(Thumbnail.ContentType, URL?)
		case gradient(ImageResource)
	}
}
