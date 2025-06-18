import SwiftUI

// MARK: - Discover.View
extension Discover {
	struct View: SwiftUI.View {
		let store: StoreOf<Discover>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				VStack(spacing: .zero) {
					Text("Discover")
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
			HStack {
				Text("Community").textStyle(.body1Header)
				Spacer()
			}
		}
	}

	@ViewBuilder
	var learnSection: some SwiftUI.View {
		Section {
			VStack(spacing: .small1) {
				ForEach(store.learnItems.prefix(3)) { item in
					Card(action: {
						store.send(.view(.learnItemTapped(item)))
					}) {
						PlainListRow(
							title: item.title,
							subtitle: item.description,
							accessory: nil,
						) {
							Image(item.icon)
								.resizable()
								.scaledToFit()
								.frame(.small)
						}
					}
				}
			}
		} header: {
			HStack {
				Text("Learn about").textStyle(.body1Header)
				Spacer()
				Button("See More") {
					store.send(.view(.seeMoreLearnItemsTapped))
				}
				.buttonStyle(.blueText)
			}
		}
	}

	@ViewBuilder
	var blogPostsSection: some SwiftUI.View {
		Section {
			Discover.BlogPostsCarousel.View(store: store.scope(state: \.blogPostsCarousel, action: \.child.blogPostsCarousel))
		} header: {
			HStack {
				Text("Blog posts").textStyle(.body1Header)
				Spacer()
				Button("See More") {
					store.send(.view(.seeMoreBlogPostsTapped))
				}
				.buttonStyle(.blueText)
			}
			.padding(.horizontal, .medium3)
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
