import FeaturePrelude
import ProfileClient

// MARK: - PersonaProfile
public struct PersonaProfile: Sendable, FeatureReducer {
	@Dependency(\.profileClient) var profileClient
	public typealias Store = StoreOf<Self>

	public init() {}

	public struct State: Sendable, Hashable {
		public let dAppName: String
		public let personaName: String
		public let firstName: String
		public let secondName: String
		public let streetAddress: String
		public let twitterName: String

		public init(dAppName: String, personaName: String, firstName: String, secondName: String, streetAddress: String, twitterName: String) {
			self.dAppName = dAppName
			self.personaName = personaName
			self.firstName = firstName
			self.secondName = secondName
			self.streetAddress = streetAddress
			self.twitterName = twitterName
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case editPersonaTapped
		case accountTapped(AccountAddress)
		case editAccountSharingTapped
		case disconnectPersonaTapped
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .none
		case .editPersonaTapped:
			return .none
		case let .accountTapped(address):
			return .none
		case .editAccountSharingTapped:
			return .none
		case .disconnectPersonaTapped:
			return .none
		}
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
