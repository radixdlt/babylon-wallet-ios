// MARK: - Discover
@Reducer
struct Discover: Sendable, FeatureReducer {
	@ObservableState
	struct State: Sendable, Hashable {
		init() {}
	}

	typealias Action = FeatureAction<Self>

	enum ViewAction: Sendable, Equatable {
		case appeared
		case socialLinkTapped(SocialLink)
		case learnItemTapped(LearnItem)
	}

	@Dependency(\.openURL) var openURL
	@Dependency(\.overlayWindowClient) var overlayWindowClient

	var body: some ReducerOf<Self> {
		Reduce(core)
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			return .none
		case let .socialLinkTapped(link):
			return .run { _ in
				await openURL(link.url)
			}
		case let .learnItemTapped(item):
			overlayWindowClient.showInfoLink(.init(glossaryItem: item.id))
			return .none
		}
	}
}

extension Discover.State {
	var socialLinks: IdentifiedArrayOf<Discover.SocialLink> {
		Discover.SocialLink.radixSocials
	}

	var learnItems: IdentifiedArrayOf<Discover.LearnItem> {
		let unsupported: Set<InfoLinkSheet.GlossaryItem> = [
			.arculus, .buildingshield, .emergencyfallback, .passwords, .securityshields,
		]
		return InfoLinkSheet.GlossaryItem.allCases
			.filter {
				!unsupported.contains($0)
			}
			.map(Discover.LearnItem.init)
			.shuffled()
			.asIdentified()
	}
}

extension Discover {
	struct SocialLink: Identifiable, Equatable, Sendable {
		var id: URL {
			url
		}

		let platform: Platform
		let description: String
		let url: URL
	}

	struct LearnItem: Identifiable, Equatable, Sendable {
		let id: InfoLinkSheet.GlossaryItem
		let icon: ImageResource
		let title: String
		let description: String

		init(glossaryItem: InfoLinkSheet.GlossaryItem) {
			self.id = glossaryItem
			self.icon = glossaryItem.image ?? .info
			self.title = glossaryItem.learnItemTitle
			self.description = glossaryItem.learnItemDescription
		}
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
			.init(platform: .x, description: "Radix X Official", url: URL(string: "https://x.com/radixdlt")!),
			.init(platform: .telegram, description: "Radix Telegram Official", url: URL(string: "https://t.me/radix_dlt")!),
			.init(platform: .discord, description: "Radix Discord Official", url: URL(string: "https://go.radixdlt.com/Discord")!),
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

private extension InfoLinkSheet.GlossaryItem {
	var learnItemTitle: String {
		switch self {
		case .tokens:
			L10n.InfoLink.DiscoverTitle.tokens
		case .nfts:
			L10n.InfoLink.DiscoverTitle.nfts
		case .networkstaking:
			L10n.InfoLink.DiscoverTitle.networkstaking
		case .personas:
			L10n.InfoLink.DiscoverTitle.personas
		case .dapps:
			L10n.InfoLink.DiscoverTitle.dapps
		case .guarantees:
			L10n.InfoLink.DiscoverTitle.guarantees
		case .badges:
			L10n.InfoLink.DiscoverTitle.badges
		case .poolunits:
			L10n.InfoLink.DiscoverTitle.poolunits
		case .gateways:
			L10n.InfoLink.DiscoverTitle.gateways
		case .radixconnect:
			L10n.InfoLink.DiscoverTitle.radixconnect
		case .transactionfee:
			L10n.InfoLink.DiscoverTitle.transactionfee
		case .behaviors:
			L10n.InfoLink.DiscoverTitle.behaviors
		case .claimnfts:
			L10n.InfoLink.DiscoverTitle.claimnfts
		case .liquidstakeunits:
			L10n.InfoLink.DiscoverTitle.liquidstakeunits
		case .radixnetwork:
			L10n.InfoLink.DiscoverTitle.radixnetwork
		case .accounts:
			L10n.InfoLink.DiscoverTitle.accounts
		case .radixwallet:
			L10n.InfoLink.DiscoverTitle.radixwallet
		case .transactions:
			L10n.InfoLink.DiscoverTitle.transactions
		case .dex:
			L10n.InfoLink.DiscoverTitle.dex
		case .validators:
			L10n.InfoLink.DiscoverTitle.validators
		case .radixconnector:
			L10n.InfoLink.DiscoverTitle.radixconnector
		case .connectbutton:
			L10n.InfoLink.DiscoverTitle.connectbutton
		case .xrd:
			L10n.InfoLink.DiscoverTitle.xrd
		case .web3:
			L10n.InfoLink.DiscoverTitle.web3
		case .transfers:
			L10n.InfoLink.DiscoverTitle.transfers
		case .dashboard:
			L10n.InfoLink.DiscoverTitle.dashboard
		case .bridging:
			L10n.InfoLink.DiscoverTitle.bridging
		case .payingaccount:
			L10n.InfoLink.DiscoverTitle.payingaccount
		case .preauthorizations:
			L10n.InfoLink.DiscoverTitle.preauthorizations
		case .possibledappcalls:
			L10n.InfoLink.DiscoverTitle.possibledappcalls
		case .biometricspin:
			L10n.InfoLink.DiscoverTitle.biometricspin
		case .ledgernano:
			L10n.InfoLink.DiscoverTitle.ledgernano
		case .passphrases:
			L10n.InfoLink.DiscoverTitle.passphrases
		case .arculus:
			L10n.InfoLink.DiscoverTitle.arculus
		case .passwords:
			L10n.InfoLink.DiscoverTitle.passwords
		case .securityshields:
			L10n.InfoLink.DiscoverTitle.securityshields
		case .buildingshield:
			L10n.InfoLink.DiscoverTitle.buildingshield
		case .emergencyfallback:
			L10n.InfoLink.DiscoverTitle.emergencyfallback
		}
	}

	var learnItemDescription: String {
		switch self {
		case .tokens:
			L10n.InfoLink.DiscoverDescription.tokens
		case .nfts:
			L10n.InfoLink.DiscoverDescription.nfts
		case .networkstaking:
			L10n.InfoLink.DiscoverDescription.networkstaking
		case .personas:
			L10n.InfoLink.DiscoverDescription.personas
		case .dapps:
			L10n.InfoLink.DiscoverDescription.dapps
		case .guarantees:
			L10n.InfoLink.DiscoverDescription.guarantees
		case .badges:
			L10n.InfoLink.DiscoverDescription.badges
		case .poolunits:
			L10n.InfoLink.DiscoverDescription.poolunits
		case .gateways:
			L10n.InfoLink.DiscoverDescription.gateways
		case .radixconnect:
			L10n.InfoLink.DiscoverDescription.radixconnect
		case .transactionfee:
			L10n.InfoLink.DiscoverDescription.transactionfee
		case .behaviors:
			L10n.InfoLink.DiscoverDescription.behaviors
		case .claimnfts:
			L10n.InfoLink.DiscoverDescription.claimnfts
		case .liquidstakeunits:
			L10n.InfoLink.DiscoverDescription.liquidstakeunits
		case .radixnetwork:
			L10n.InfoLink.DiscoverDescription.radixnetwork
		case .accounts:
			L10n.InfoLink.DiscoverDescription.accounts
		case .radixwallet:
			L10n.InfoLink.DiscoverDescription.radixwallet
		case .transactions:
			L10n.InfoLink.DiscoverDescription.transactions
		case .dex:
			L10n.InfoLink.DiscoverDescription.dex
		case .validators:
			L10n.InfoLink.DiscoverDescription.validators
		case .radixconnector:
			L10n.InfoLink.DiscoverDescription.radixconnector
		case .connectbutton:
			L10n.InfoLink.DiscoverDescription.connectbutton
		case .xrd:
			L10n.InfoLink.DiscoverDescription.xrd
		case .web3:
			L10n.InfoLink.DiscoverDescription.web3
		case .transfers:
			L10n.InfoLink.DiscoverDescription.transfers
		case .dashboard:
			L10n.InfoLink.DiscoverDescription.dashboard
		case .bridging:
			L10n.InfoLink.DiscoverDescription.bridging
		case .payingaccount:
			L10n.InfoLink.DiscoverDescription.payingaccount
		case .preauthorizations:
			L10n.InfoLink.DiscoverDescription.preauthorizations
		case .possibledappcalls:
			L10n.InfoLink.DiscoverDescription.possibledappcalls
		case .biometricspin:
			L10n.InfoLink.DiscoverDescription.biometricspin
		case .ledgernano:
			L10n.InfoLink.DiscoverDescription.ledgernano
		case .passphrases:
			L10n.InfoLink.DiscoverDescription.passphrases
		case .arculus:
			L10n.InfoLink.DiscoverDescription.arculus
		case .passwords:
			L10n.InfoLink.DiscoverDescription.passwords
		case .securityshields:
			L10n.InfoLink.DiscoverDescription.securityshields
		case .buildingshield:
			L10n.InfoLink.DiscoverDescription.buildingshield
		case .emergencyfallback:
			L10n.InfoLink.DiscoverDescription.emergencyfallback
		}
	}
}
