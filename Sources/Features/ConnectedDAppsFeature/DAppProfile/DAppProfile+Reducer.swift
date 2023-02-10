import FeaturePrelude

// MARK: - DAppProfile
public struct DAppProfile: Sendable, FeatureReducer {
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
		case let .didSelectPersona(persona):
			// TODO: • This proxying is only necessary because of our strict view/child separation
			return .send(.child(.selectedPersona(.present(.init(persona: persona)))))
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
			self.dApp = .debug(name)
			self.selectedPersona = selectedPersona
		}
	}
}

// MARK: - Action

public extension DAppProfile {
	enum ViewAction: Sendable, Equatable {
		case appeared
		case didSelectPersona(String)
	}

	enum ChildAction: Sendable, Equatable {
		case selectedPersona(PresentationActionOf<PersonaProfile>)
	}
}

// MARK: - DAppProfileModel
public struct DAppProfileModel: Identifiable, Hashable, Sendable {
	public let id: UUID = .init()
	let name: String
	let description: String
	let domainNames: [String]
	let tokens: Int
}

extension DAppProfileModel {
	static func debug(_ name: String) -> DAppProfileModel {
		.init(name: name,
		      description: .nbaTopShot,
		      domainNames: ["https://nft.nike.com", "https://meta-radix.xyz"],
		      tokens: .random(in: 5 ... 20))
	}
}

extension String {
	static let nbaTopShot: String = "NBA Top Shot is a decentralized application that provides users with the opportunity to purchase, collect, and showcase digital blockchain collectibles"

	static let lorem: String = "Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo. Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt."
}
