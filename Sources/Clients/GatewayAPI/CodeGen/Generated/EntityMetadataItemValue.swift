import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.EntityMetadataItemValue")
public typealias EntityMetadataItemValue = GatewayAPI.EntityMetadataItemValue

// MARK: - GatewayAPI.EntityMetadataItemValue
extension GatewayAPI {
	public struct EntityMetadataItemValue: Codable, Hashable {
		public private(set) var rawHex: String
		public private(set) var rawJson: AnyCodable
		public private(set) var asString: String?
		public private(set) var asStringCollection: [String]?

		public init(rawHex: String, rawJson: AnyCodable, asString: String? = nil, asStringCollection: [String]? = nil) {
			self.rawHex = rawHex
			self.rawJson = rawJson
			self.asString = asString
			self.asStringCollection = asStringCollection
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case rawHex = "raw_hex"
			case rawJson = "raw_json"
			case asString = "as_string"
			case asStringCollection = "as_string_collection"
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(rawHex, forKey: .rawHex)
			try container.encode(rawJson, forKey: .rawJson)
			try container.encodeIfPresent(asString, forKey: .asString)
			try container.encodeIfPresent(asStringCollection, forKey: .asStringCollection)
		}
	}
}
