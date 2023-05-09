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

// MARK: - DappDefinitionAddress
/// YES! DappDefinitionAddress **is** an AccountAddress! NOT to be confused with the
/// address the an component on Ledger, the `DappAddress`.
public enum DappDefinitionAddress: Sendable, Hashable {
	/// A dAppDefinition address is a valid AccountAddress.
	case valid(AccountAddress)

	/// In case `isDeveloperModeEnabled` is `true`, we allow invalid dAppDefinitiion addresses.
	case invalid(String)
}
