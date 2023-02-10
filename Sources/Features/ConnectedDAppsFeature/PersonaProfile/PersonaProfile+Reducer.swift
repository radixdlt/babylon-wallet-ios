import FeaturePrelude

// MARK: - PersonaProfile
public struct PersonaProfile: Sendable, FeatureReducer {
	public typealias Store = StoreOf<Self>

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .none
		}
	}
}

// MARK: PersonaProfile.State
public extension PersonaProfile {
	struct State: Sendable, Hashable {
		let persona: String

		public init(persona: String) {
			self.persona = persona
		}
	}
}

// MARK: PersonaProfile.ViewAction
public extension PersonaProfile {
	enum ViewAction: Sendable, Equatable {
		case appeared
	}
}

// MARK: - PersonaProfileRowModel
public struct PersonaProfileRowModel: Identifiable, Hashable, Sendable {
	public let id: UUID = .init()
	let thumbnail: URL = .placeholder
	let name: String
	let sharingStatus: String = "Sharing"
	let personalDataCount: Int
	let accountCount: Int
}

extension [PersonaProfileRowModel] {
	static let debug: [PersonaProfileRowModel] = [
		.init(name: "RadMatt", personalDataCount: 3, accountCount: 2),
		.init(name: "MattMountain", personalDataCount: 4, accountCount: 1),
		.init(name: "RonaldMcD", personalDataCount: 2, accountCount: 1),
	]
}
