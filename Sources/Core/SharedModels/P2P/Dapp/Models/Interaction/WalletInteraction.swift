import EngineToolkitModels
import Prelude
import Profile

// MARK: - P2P.Dapp.Request
extension P2P.Dapp {
	public struct Request: Sendable, Hashable, Decodable, Identifiable {
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
		) {
			self.id = id
			self.items = items
			self.metadata = metadata
		}
	}
}

// MARK: - P2P.Dapp.Request.Metadata
extension P2P.Dapp.Request {
	public struct Metadata: Sendable, Hashable, Decodable {
		public typealias Origin = Tagged<(Self, origin: ()), String>

		public let networkId: NetworkID
		public let origin: Origin
		public let dAppDefinitionAddress: DappDefinitionAddress

		public init(
			networkId: NetworkID,
			origin: Origin,
			dAppDefinitionAddress: DappDefinitionAddress
		) {
			self.networkId = networkId
			self.origin = origin
			self.dAppDefinitionAddress = dAppDefinitionAddress
		}
	}
}
