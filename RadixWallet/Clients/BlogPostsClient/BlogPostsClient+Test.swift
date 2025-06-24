extension DependencyValues {
	public var blogPostsClient: BlogPostsClient {
		get { self[BlogPostsClient.self] }
		set { self[BlogPostsClient.self] = newValue }
	}
}

// MARK: - BlogPostsClient + TestDependencyKey
extension BlogPostsClient: TestDependencyKey {
	public static let previewValue = Self(loadBlogPosts: unimplemented("\(Self.self).loadBlogPosts"))
	public static let testValue = Self(loadBlogPosts: unimplemented("\(Self.self).loadBlogPosts"))
}
