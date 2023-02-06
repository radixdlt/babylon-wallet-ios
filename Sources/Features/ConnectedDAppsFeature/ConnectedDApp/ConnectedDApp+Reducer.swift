import FeaturePrelude

// MARK: - Reducer

public struct ConnectedDApp: Sendable, FeatureReducer {
	public typealias Store = StoreOf<Self>

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.presentationDestination(\.selectedPersona, action: /Action.child .. ChildAction.selectedPersona) {
				DAppPersona()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .none
		case .didSelectPersona(let persona):
			// TODO: • This proxying is only necessary because of our strict view/child separation
			return .send(.child(.selectedPersona(.present(.init(persona: persona)))))
		}
	}
}

// MARK: - State

public extension ConnectedDApp {
	struct State: Sendable, Hashable {
		public let name: String
		public let personas: [DAppPersonaRowModel] = .debug
		public let dApp: ConnectedDAppModel

		public var selectedPersona: PresentationStateOf<DAppPersona>
		
		public init(name: String, selectedPersona: PresentationStateOf<DAppPersona> = .dismissed) {
			self.name = name
			self.dApp = .debug(name)
			self.selectedPersona = selectedPersona
		}
	}
}

// MARK: - Action

public extension ConnectedDApp {
	enum ViewAction: Sendable, Equatable {
		case appeared
		case didSelectPersona(String)
	}
	
	enum ChildAction: Sendable, Equatable {
		case selectedPersona(PresentationActionOf<DAppPersona>)
	}
}

// MARK: - For Debugging

public struct ConnectedDAppModel: Identifiable, Hashable, Sendable {
	public let id: UUID = .init()
	let name: String
	let description: String
	let domainNames: [String]
	let tokens: Int
}

extension ConnectedDAppModel {
	static func debug(_ name: String) -> ConnectedDAppModel {
		.init(name: name,
			  description: .lorem,
			  domainNames: ["https://nft.nike.com", "https://meta-radix.xyz"],
			  tokens: .random(in: 5...20))
	}
}

public struct DAppPersonaRowModel: Identifiable, Hashable, Sendable {
	public let id: UUID = .init()
	let thumbnail: URL = .placeholder
	let name: String
	let sharingStatus: String = "Sharing"
	let personalDataCount: Int
	let accountCount: Int
}

extension [DAppPersonaRowModel] {
	static let debug: [DAppPersonaRowModel] = [
		.init(name: "RadMatt", personalDataCount: 3, accountCount: 2),
		.init(name: "MattMountain", personalDataCount: 4, accountCount: 1),
		.init(name: "RonaldMcD", personalDataCount: 2, accountCount: 1)
	]
}

extension String {
	static let lorem: String = "Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo. Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt."
}

