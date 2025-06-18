// MARK: - BlogPosts

extension Discover {
	@Reducer
	struct AllBlogPosts: Sendable, FeatureReducer {
		@ObservableState
		struct State: Sendable, Hashable {
			var posts: Loadable<BlogPosts> = .idle
			init() {}
		}

		typealias Action = FeatureAction<Self>

		enum ViewAction: Sendable, Equatable {
			case task
		}

		enum InternalAction: Sendable, Equatable {
			case postsLoaded(BlogPosts)
		}

		@Dependency(\.blogPostsClient) var blogPostsClient

		var body: some ReducerOf<Self> {
			Reduce(core)
		}

		func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
			switch viewAction {
			case .task:
				guard !state.posts.isSuccess else {
					return .none
				}
				state.posts = .loading
				return .run { send in
					let posts = try await blogPostsClient.loadBlogPosts()
					await send(.internal(.postsLoaded(posts)))
				} catch: { err, _ in
					print(err.localizedDescription)
				}
			}
		}

		func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
			switch internalAction {
			case let .postsLoaded(blogPosts):
				state.posts = .success(blogPosts)
				return .none
			}
		}
	}
}
