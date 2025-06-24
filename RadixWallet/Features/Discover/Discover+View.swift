import SwiftUI

// MARK: - Discover.View
extension Discover {
	struct View: SwiftUI.View {
		let store: StoreOf<Discover>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				VStack(spacing: .zero) {
					Text(L10n.Discover.title)
						.foregroundColor(Color.primaryText)
						.textStyle(.body1Header)
						.padding(.vertical, .small1)
						.frame(maxWidth: .infinity)
						.background(.primaryBackground)

					Separator()

					ScrollView {
						VStack(spacing: .medium1) {
							blogPostsSection
							socialsSection
								.padding(.horizontal, .medium3)
							learnSection
								.padding(.horizontal, .medium3)
						}
						.padding(.vertical, .medium3)
					}
					.background(.secondaryBackground)
				}
				.destinations(store: store)
			}
		}
	}
}

extension Discover.View {
	@ViewBuilder
	var socialsSection: some SwiftUI.View {
		Section {
			VStack(spacing: .small1) {
				ForEach(store.socialLinks) { link in
					Card(action: {
						store.send(.view(.socialLinkTapped(link)))
					}) {
						PlainListRow(title: link.name, subtitle: link.description, accessory: .iconLinkOut, icon: {
							Image(link.platform.icon)
								.resizable()
								.scaledToFit()
								.frame(.small)
						})
					}
				}
			}
		} header: {
			sectionHeader(
				title: L10n.Discover.CategoryCommunity.title
			)
		}
	}

	@ViewBuilder
	var learnSection: some SwiftUI.View {
		Section {
			Discover.LearnItemsList.View(store: store.scope(state: \.learnItemsList, action: \.child.learnItemsList))
		} header: {
			sectionHeader(
				title: L10n.Discover.CategoryLearn.title,
				seeMoreAction: .seeMoreLearnItemsTapped
			)
		}
	}

	@ViewBuilder
	var blogPostsSection: some SwiftUI.View {
		Section {
			Discover.BlogPostsCarousel.View(store: store.scope(state: \.blogPostsCarousel, action: \.child.blogPostsCarousel))
		} header: {
			sectionHeader(
				title: L10n.Discover.CategoryBlogPosts.title,
				seeMoreAction: .seeMoreBlogPostsTapped
			)
			.padding(.horizontal, .medium3)
		}
	}

	@ViewBuilder
	func sectionHeader(title: String, seeMoreAction: Discover.ViewAction? = nil) -> some SwiftUI.View {
		HStack {
			Text(title)
				.textStyle(.sectionHeader)
			Spacer()
			if let seeMoreAction {
				Button(L10n.Discover.SeeMore.button) {
					store.send(.view(seeMoreAction))
				}
				.buttonStyle(.blueText)
			}
		}
	}
}

private extension View {
	func destinations(store: StoreOf<Discover>) -> some View {
		let destinationStore = store.scope(state: \.$destination, action: \.destination)

		return navigationDestination(store: destinationStore.scope(state: \.learnAbout, action: \.learnAbout)) {
			Discover.LearnAbout.View(store: $0)
		}
		.navigationDestination(store: destinationStore.scope(state: \.blogPosts, action: \.blogPosts)) {
			Discover.AllBlogPosts.View(store: $0)
		}
	}
}
