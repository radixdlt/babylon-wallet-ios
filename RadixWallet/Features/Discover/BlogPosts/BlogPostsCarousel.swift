// MARK: - BlogPostsCarousel
extension Discover {
	@Reducer
	struct BlogPostsCarousel: Sendable, FeatureReducer {
		@ObservableState
		struct State: Sendable, Hashable {
			var posts: Loadable<BlogPosts> = .idle
		}

		typealias Action = FeatureAction<Self>

		enum ViewAction: Sendable, Equatable {
			case task
			case refreshButtonTapped
		}

		enum InternalAction: Sendable, Equatable {
			case loadPostsResult(TaskResult<BlogPosts>)
		}

		@Dependency(\.blogPostsClient) var blogPostsClient
		@Dependency(\.errorQueue) var errorQueue

		var body: some ReducerOf<Self> {
			Reduce(core)
		}

		func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
			switch viewAction {
			case .task:
				guard !state.posts.isSuccess else {
					return .none
				}
				return loadBlogPosts(state: &state)
			case .refreshButtonTapped:
				return loadBlogPosts(state: &state)
			}
		}

		func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
			switch internalAction {
			case let .loadPostsResult(result):
				state.posts.refresh(from: .init(result: result))
				return .none
			}
		}

		func loadBlogPosts(state: inout State) -> Effect<Action> {
			state.posts.refresh(from: .loading)
			return .run { send in
				let loadResult = await TaskResult { try await blogPostsClient.loadBlogPosts() }
				await send(.internal(.loadPostsResult(loadResult)))
			} catch: { error, _ in
				errorQueue.schedule(error)
			}
		}
	}
}
