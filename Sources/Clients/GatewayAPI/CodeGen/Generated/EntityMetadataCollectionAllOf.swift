import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.EntityMetadataCollectionAllOf")
public typealias EntityMetadataCollectionAllOf = GatewayAPI.EntityMetadataCollectionAllOf

// MARK: - GatewayAPI.EntityMetadataCollectionAllOf
extension GatewayAPI {
	public struct EntityMetadataCollectionAllOf: Codable, Hashable {
		public private(set) var items: [EntityMetadataItem]

		public init(items: [EntityMetadataItem]) {
			self.items = items
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case items
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(items, forKey: .items)
		}
	}
}
