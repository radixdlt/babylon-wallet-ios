import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.EntityMetadataItem")
public typealias EntityMetadataItem = GatewayAPI.EntityMetadataItem

// MARK: - GatewayAPI.EntityMetadataItem
extension GatewayAPI {
	/** Entity metadata key-value pair. */
	public struct EntityMetadataItem: Codable, Hashable {
		/** Entity metadata key. */
		public private(set) var key: String
		public private(set) var value: EntityMetadataItemValue
		/** TBD */
		public private(set) var lastUpdatedAtStateVersion: Int64

		public init(key: String, value: EntityMetadataItemValue, lastUpdatedAtStateVersion: Int64) {
			self.key = key
			self.value = value
			self.lastUpdatedAtStateVersion = lastUpdatedAtStateVersion
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case key
			case value
			case lastUpdatedAtStateVersion = "last_updated_at_state_version"
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(key, forKey: .key)
			try container.encode(value, forKey: .value)
			try container.encode(lastUpdatedAtStateVersion, forKey: .lastUpdatedAtStateVersion)
		}
	}
}
