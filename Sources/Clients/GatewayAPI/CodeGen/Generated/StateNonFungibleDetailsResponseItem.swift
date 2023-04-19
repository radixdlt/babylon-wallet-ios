import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.StateNonFungibleDetailsResponseItem")
public typealias StateNonFungibleDetailsResponseItem = GatewayAPI.StateNonFungibleDetailsResponseItem

// MARK: - GatewayAPI.StateNonFungibleDetailsResponseItem
extension GatewayAPI {
	public struct StateNonFungibleDetailsResponseItem: Codable, Hashable {
		/** String-encoded non-fungible ID. */
		public private(set) var nonFungibleId: String
		public private(set) var mutableData: ScryptoSborValue
		public private(set) var immutableData: ScryptoSborValue
		/** TBD */
		public private(set) var lastUpdatedAtStateVersion: Int64

		public init(nonFungibleId: String, mutableData: ScryptoSborValue, immutableData: ScryptoSborValue, lastUpdatedAtStateVersion: Int64) {
			self.nonFungibleId = nonFungibleId
			self.mutableData = mutableData
			self.immutableData = immutableData
			self.lastUpdatedAtStateVersion = lastUpdatedAtStateVersion
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case nonFungibleId = "non_fungible_id"
			case mutableData = "mutable_data"
			case immutableData = "immutable_data"
			case lastUpdatedAtStateVersion = "last_updated_at_state_version"
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(nonFungibleId, forKey: .nonFungibleId)
			try container.encode(mutableData, forKey: .mutableData)
			try container.encode(immutableData, forKey: .immutableData)
			try container.encode(lastUpdatedAtStateVersion, forKey: .lastUpdatedAtStateVersion)
		}
	}
}
