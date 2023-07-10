import Prelude
import Profile

// MARK: - P2P.Dapp.Request
extension P2P.Dapp {
	public typealias Version = Tagged<Self, UInt>
	/// Temporarily disables Dapp communication.
	/// Should be reverted as soon as we implement [ABW-1872](https://radixdlt.atlassian.net/browse/ABW-1872)
	public static let currentVersion: Version = 1

	public struct Request: Sendable, Hashable, Identifiable {
		public typealias ID = RequestUnvalidated.ID

		public let id: ID
		public let items: Items
		public let metadata: Metadata

		public init(id: ID, items: Items, metadata: Metadata) {
			self.id = id
			self.items = items
			self.metadata = metadata
		}
	}

	public struct RequestUnvalidated: Sendable, Hashable, Decodable, Identifiable {
		private enum CodingKeys: String, CodingKey {
			case id = "interactionId"
			case items
			case metadata
		}

		public typealias ID = Tagged<Self, String>

		public let id: ID
		public let items: P2P.Dapp.Request.Items
		public let metadata: P2P.Dapp.Request.MetadataUnvalidated

		public init(
			id: ID,
			items: P2P.Dapp.Request.Items,
			metadata: P2P.Dapp.Request.MetadataUnvalidated
		) {
			self.id = id
			self.items = items
			self.metadata = metadata
		}
	}
}

// MARK: - P2P.Dapp.Request.Metadata
extension P2P.Dapp.Request {
	/// The metadata sent with the request from the Dapp.
	/// not to be confused with `DappMetadata` which can hold a value of this type
	public struct Metadata: Sendable, Hashable, Decodable {
		public typealias Origin = DappOrigin

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

// MARK: - P2P.Dapp.Request.MetadataUnvalidated
extension P2P.Dapp.Request {
	public struct MetadataUnvalidated: Sendable, Hashable, Decodable {
		public let version: P2P.Dapp.Version
		public let networkId: NetworkID
		public let origin: String

		/// Non yet validated dAppDefinitionAddresss
		public let dAppDefinitionAddress: String

		public init(
			version: P2P.Dapp.Version,
			networkId: NetworkID,
			origin: String,
			dAppDefinitionAddress: String
		) {
			self.version = version
			self.networkId = networkId
			self.origin = origin
			self.dAppDefinitionAddress = dAppDefinitionAddress
		}
	}
}
