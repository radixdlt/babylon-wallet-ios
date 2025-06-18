// MARK: - BlogPostsClient + DependencyKey
extension BlogPostsClient: DependencyKey {
	public typealias Value = BlogPostsClient

	public static let liveValue = {
		let client = Sargon.BlogPostsClient(networkingDriver: URLSession.shared, fileSystemDriver: FileSystem.shared)

		return Self(
			loadBlogPosts: {
				try await client.getBlogPosts()
			}
		)
	}()
}

// MARK: - Sargon.BlogPostsClient + @unchecked @retroactive Sendable
extension Sargon.BlogPostsClient: @unchecked @retroactive Sendable {}
