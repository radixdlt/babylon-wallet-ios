import SwiftUI

// MARK: - BlogPostsCarousel.View
extension Discover.BlogPostsCarousel {
	struct View: SwiftUI.View {
		static let numberOfDisplayedBlogPosts = 3
		let store: StoreOf<Discover.BlogPostsCarousel>
		@SwiftUI.State private var selectedCardIndex = 0

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				VStack {
					loadable(
						store.posts,
						loadingView: loadingView,
						errorView: errorView,
						successContent: successView
					)
				}
				.onFirstTask { await store.send(.view(.task)).finish() }
			}
		}

		@ViewBuilder
		private func errorView(_ error: Error) -> some SwiftUI.View {
			VStack(spacing: .small2) {
				Image(systemName: "arrow.clockwise")
					.resizable()
					.aspectRatio(contentMode: .fit)
					.frame(.small)

				Text(L10n.Discover.BlogPosts.Failure.title)
					.foregroundStyle(.primaryText)
					.textStyle(.body1Header)
					.padding(.top, .medium3)
				Button(L10n.Discover.BlogPosts.Failure.Cta.button) {
					store.send(.view(.refreshButtonTapped))
				}
				.buttonStyle(.secondaryRectangular)
			}
			.padding(.top, .medium3)
			.frame(maxWidth: .infinity)
		}

		@ViewBuilder
		private func loadingView() -> some SwiftUI.View {
			VStack {
				TabView(selection: $selectedCardIndex) {
					ForEach(0 ..< 3) { idx in
						Rectangle()
							.shimmeringLoadingView(height: 240)
							.padding(.horizontal, .medium3)
							.tag(idx)
					}
				}
				.tabViewStyle(.page(indexDisplayMode: .never))
				.frame(height: 240)
				positionIndicator
			}
		}

		@ViewBuilder
		private func successView(_ posts: BlogPosts) -> some SwiftUI.View {
			VStack {
				postsView(posts)
					.frame(height: 240)
				positionIndicator
			}
		}

		@ViewBuilder
		private func postsView(_ posts: BlogPosts) -> some SwiftUI.View {
			TabView(selection: $selectedCardIndex) {
				ForEach(Array(posts.posts.prefix(Self.numberOfDisplayedBlogPosts).enumerated()), id: \.offset) { idx, post in
					BlogPostCard(post: post, imageSizingBehavior: nil, dropShadow: false)
						.padding(.horizontal, .medium3)
						.tag(idx)
				}
			}
			.tabViewStyle(.page(indexDisplayMode: .never))
		}

		@ViewBuilder
		private var positionIndicator: some SwiftUI.View {
			HStack(spacing: .small2) {
				ForEach(0 ..< 3, id: \.self) { index in
					let isSelected = selectedCardIndex == index
					Capsule()
						.fill(isSelected ? .iconSecondary : .iconTertiary)
						.frame(isSelected ? .small2 : .small3)
				}
			}
		}
	}
}
