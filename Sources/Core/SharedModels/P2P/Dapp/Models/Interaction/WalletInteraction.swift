import EngineToolkitModels
import Prelude
import Profile

// MARK: - P2P.Dapp.Request
extension P2P.Dapp {
	public typealias Version = Tagged<Self, UInt>
	public static let currentVersion: Version = 1
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

		public let version: P2P.Dapp.Version
		public let networkId: NetworkID
		public let origin: Origin
		public let dAppDefinitionAddress: DappDefinitionAddress

		public init(
			version: P2P.Dapp.Version,
			networkId: NetworkID,
			origin: Origin,
			dAppDefinitionAddress: DappDefinitionAddress
		) {
			self.version = version
			self.networkId = networkId
			self.origin = origin
			self.dAppDefinitionAddress = dAppDefinitionAddress
		}
	}
}
