import SwiftUI

// MARK: - BlogPosts.View
extension Discover.AllBlogPosts {
	struct View: SwiftUI.View {
		let store: StoreOf<Discover.AllBlogPosts>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				ScrollView {
					loadable(
						store.posts,
						loadingView: loadingView,
						successContent: successView
					)
					.padding()
				}
				.onFirstTask { await store.send(.view(.task)).finish() }
			}
			.background(.secondaryBackground)
			.radixToolbar(title: "Blog Posts")
		}

		@ViewBuilder
		func errorView(_ error: Error) -> some SwiftUI.View {
			VStack(spacing: .zero) {
				Image(systemName: "arrow.clockwise")
					.resizable()
					.aspectRatio(contentMode: .fit)
					.frame(.small)

				Text(L10n.DappDirectory.Error.heading)
					.foregroundStyle(.primaryText)
					.textStyle(.body1Header)
					.padding(.top, .medium3)
				Text(L10n.DappDirectory.Error.message)
					.foregroundStyle(.secondaryText)
					.textStyle(.body1HighImportance)
					.padding(.top, .small3)
			}
			.padding(.top, .huge1)
			.frame(maxWidth: .infinity)
		}

		@ViewBuilder
		func loadingView() -> some SwiftUI.View {
			VStack(spacing: .medium3) {
				ForEach(0 ..< 20) { _ in
					Rectangle()
						.shimmeringLoadingView(height: 320)
				}
			}
		}

		@ViewBuilder
		func successView(_ posts: BlogPosts) -> some SwiftUI.View {
			VStack(spacing: .medium3) {
				ForEach(posts.posts, id: \.url) { post in
					BlogPostCard(post: post, imageSizingBehavior: .flexible(minAspect: 1, maxAspect: 2), dropShadow: true)
				}

				Button("See all Blog Posts") {}
					.buttonStyle(.url)
			}
		}
	}
}
