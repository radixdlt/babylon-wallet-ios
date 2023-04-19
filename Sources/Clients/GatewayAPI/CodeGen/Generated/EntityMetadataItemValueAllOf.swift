import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.EntityMetadataItemValueAllOf")
public typealias EntityMetadataItemValueAllOf = GatewayAPI.EntityMetadataItemValueAllOf

// MARK: - GatewayAPI.EntityMetadataItemValueAllOf
extension GatewayAPI {
	public struct EntityMetadataItemValueAllOf: Codable, Hashable {
		public private(set) var asString: String?
		public private(set) var asStringCollection: [String]?

		public init(asString: String? = nil, asStringCollection: [String]? = nil) {
			self.asString = asString
			self.asStringCollection = asStringCollection
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case asString = "as_string"
			case asStringCollection = "as_string_collection"
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encodeIfPresent(asString, forKey: .asString)
			try container.encodeIfPresent(asStringCollection, forKey: .asStringCollection)
		}
	}
}
