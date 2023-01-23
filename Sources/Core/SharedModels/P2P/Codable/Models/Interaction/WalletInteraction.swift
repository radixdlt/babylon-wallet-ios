import EngineToolkitModels
import Prelude

// MARK: - P2P.FromDapp
public extension P2P {
	/// Just a namespace
	enum FromDapp {}
}

// MARK: - P2P.FromDapp.WalletInteraction
public extension P2P.FromDapp {
	struct WalletInteraction: Sendable, Hashable, Decodable, Identifiable {
		private enum CodingKeys: String, CodingKey {
			case id = "interactionId"
			case items
			case metadata
		}

		public typealias ID = Tagged<(Self, id: ()), String>

		public let id: ID
		public let items: Items
		public let metadata: Metadata

		public init(
			id: ID,
			items: Items,
			metadata: Metadata
		) throws {
			self.id = id
			self.items = items
			self.metadata = metadata
		}
	}
}

// MARK: - P2P.FromDapp.WalletInteraction.Metadata
public extension P2P.FromDapp.WalletInteraction {
	struct Metadata: Sendable, Hashable, Decodable {
		public typealias Origin = Tagged<(Self, origin: ()), String>
		public typealias DAppID = Tagged<(Self, dAppId: ()), String>

		public let networkId: NetworkID
		public let origin: Origin
		public let dAppId: DAppID

		public init(networkId: NetworkID, origin: Origin, dAppId: DAppID) {
			self.networkId = networkId
			self.origin = origin
			self.dAppId = dAppId
		}
	}
}
