// MARK: - Discover
@Reducer
struct Discover: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		var blogPostsCarousel: BlogPostsCarousel.State = .init()
		var learnItemsList: LearnItemsList.State = .withPreviewItems()

		@Presents
		var destination: Destination.State? = nil
	}

	typealias Action = FeatureAction<Self>

	enum ViewAction: Sendable, Equatable {
		case socialLinkTapped(SocialLink)
		case seeMoreLearnItemsTapped
		case seeMoreBlogPostsTapped
	}

	@CasePathable
	enum ChildAction: Sendable, Equatable {
		case blogPostsCarousel(BlogPostsCarousel.Action)
		case learnItemsList(LearnItemsList.Action)
	}

	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Hashable, Sendable {
			case blogPosts(AllBlogPosts.State)
			case learnAbout(LearnAbout.State)
		}

		@CasePathable
		enum Action: Equatable, Sendable {
			case blogPosts(AllBlogPosts.Action)
			case learnAbout(LearnAbout.Action)
		}

		var body: some ReducerOf<Self> {
			Scope(state: \.learnAbout, action: \.learnAbout) {
				LearnAbout()
			}

			Scope(state: \.blogPosts, action: \.blogPosts) {
				AllBlogPosts()
			}
		}
	}

	@Dependency(\.openURL) var openURL
	@Dependency(\.overlayWindowClient) var overlayWindowClient

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	var body: some ReducerOf<Self> {
		Scope(state: \.blogPostsCarousel, action: \.child.blogPostsCarousel) {
			BlogPostsCarousel()
		}

		Scope(state: \.learnItemsList, action: \.child.learnItemsList) {
			LearnItemsList()
		}

		Reduce(core)
			.ifLet(destinationPath, action: \.destination) {
				Destination()
			}
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case let .socialLinkTapped(link):
			return .run { _ in
				await openURL(link.url)
			}
		case .seeMoreLearnItemsTapped:
			state.destination = .learnAbout(.init())
			return .none
		case .seeMoreBlogPostsTapped:
			state.destination = .blogPosts(.init())
			return .none
		}
	}
}

extension Discover.State {
	var socialLinks: IdentifiedArrayOf<Discover.SocialLink> {
		Discover.SocialLink.radixSocials
	}
}

// MARK: - Discover.SocialLink
extension Discover {
	struct SocialLink: Identifiable, Equatable, Sendable {
		var id: URL {
			url
		}

		let platform: Platform
		let name: String
		let description: String
		let url: URL
	}
}

extension Discover.SocialLink {
	enum Platform: Equatable, Sendable {
		case x
		case telegram
		case discord
	}

	static var radixSocials: IdentifiedArrayOf<Self> {
		[
			.init(
				platform: .x,
				name: L10n.Discover.SocialLinks.Twitter.title,
				description: L10n.Discover.SocialLinks.Twitter.subtitle,
				url: URL(string: "https://x.com/radixdlt")!
			),
			.init(
				platform: .telegram,
				name: L10n.Discover.SocialLinks.Telegram.title,
				description: L10n.Discover.SocialLinks.Telegram.subtitle,
				url: URL(string: "https://t.me/radix_dlt")!
			),
			.init(
				platform: .discord,
				name: L10n.Discover.SocialLinks.Discord.title,
				description: L10n.Discover.SocialLinks.Discord.subtitle,
				url: URL(string: "https://go.radixdlt.com/Discord")!
			),
		]
	}
}

extension Discover.SocialLink.Platform {
	var icon: ImageResource {
		switch self {
		case .x:
			.twitter
		case .telegram:
			.telegram
		case .discord:
			.discord
		}
	}
}
