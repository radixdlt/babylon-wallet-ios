// MARK: - BlogPostsClient
public struct BlogPostsClient: Sendable {
	public var loadBlogPosts: LoadBlogPosts
}

extension BlogPostsClient {
	public typealias LoadBlogPosts = @Sendable () async throws -> BlogPosts
}
