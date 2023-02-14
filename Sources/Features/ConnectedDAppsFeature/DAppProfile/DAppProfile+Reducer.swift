import FeaturePrelude

// MARK: - DAppProfile
public struct DAppProfile: Sendable, FeatureReducer {
	@Dependency(\.openURL) var openURL
	@Dependency(\.pasteboardClient) var pasteboardClient

	public typealias Store = StoreOf<Self>

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.presentationDestination(\.$selectedPersona, action: /Action.child .. ChildAction.selectedPersona) {
				PersonaProfile()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .none
		case .copyAddressButtonTapped:
			let address = state.dApp.address.address
			return .fireAndForget {
				pasteboardClient.copyString(address)
			}
		case .openURLTapped:
			let url = state.dApp.domain
			return .fireAndForget {
				await openURL(url)
			}
		case let .tokenTapped(token):
			return .none
		case let .nftTapped(nft):
			return .none
		case let .personaTapped(persona):
			// TODO: • This proxying is only necessary because of our strict view/child separation
			return .send(.child(.selectedPersona(.present(.init(persona: persona)))))
		case .forgetThisDApp:
			return .none
		}
	}
}

// MARK: DAppProfile.State
public extension DAppProfile {
	struct State: Sendable, Hashable {
		public let name: String
		public let personas: [PersonaProfileRowModel] = .debug
		public let dApp: DAppProfileModel

		@PresentationState public var selectedPersona: PersonaProfile.State?

		public init(name: String, selectedPersona: PersonaProfile.State? = nil) {
			self.name = name
			self.dApp = .mock(name)
			self.selectedPersona = selectedPersona
		}
	}
}

// MARK: - Action

public extension DAppProfile {
	enum ViewAction: Sendable, Equatable {
		case appeared
		case openURLTapped
		case copyAddressButtonTapped
		case tokenTapped(UUID)
		case nftTapped(UUID)
		case personaTapped(String)
		case forgetThisDApp
	}

	enum ChildAction: Sendable, Equatable {
		case selectedPersona(PresentationActionOf<PersonaProfile>)
	}
}

// MARK: - DAppProfileModel
public struct DAppProfileModel: Identifiable, Hashable, Sendable {
	public let id: UUID = .init()
	let name: String
	let address: ComponentAddress
	let description: String
	let domain: URL
	let tokens: [TokenModel]
	let nfts: [TokenModel]

	public struct TokenModel: Identifiable, Hashable, Sendable {
		public let id: UUID = .init()
		let name: String
		let address: ComponentAddress = .mock
	}

	public struct NFTModel: Identifiable, Hashable, Sendable {
		public let id: UUID = .init()
		let name: String
		let address: ComponentAddress = .mock
	}
}

extension String {
	static let nbaTopShot: String = "NBA Top Shot is a decentralized application that provides users with the opportunity to purchase, collect, and showcase digital blockchain collectibles"

	static let lorem: String = "Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo. Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt."
}

extension ComponentAddress {
	static let mock = ComponentAddress(address: "component_sim1qfh2n5twmrzrlstqepsu3u624r4pdzca9pqhrcy7624sfmxzep")
}

extension DAppProfileModel {
	static func mock(_ name: String) -> Self {
		.init(name: name,
		      address: .mock,
		      description: .nbaTopShot,
		      domain: .init(string: "https://nba-topshot.xyz")!,
		      tokens: [.mock("NBA")],
		      nfts: [.mock("NBA Top Shot")])
	}
}

extension DAppProfileModel.TokenModel {
	static func mock(_ name: String) -> Self {
		.init(name: name)
	}
}

extension DAppProfileModel.NFTModel {
	static func mock(_ name: String) -> Self {
		.init(name: name)
	}
}
