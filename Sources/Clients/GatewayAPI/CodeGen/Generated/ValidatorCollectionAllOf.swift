import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.ValidatorCollectionAllOf")
public typealias ValidatorCollectionAllOf = GatewayAPI.ValidatorCollectionAllOf

// MARK: - GatewayAPI.ValidatorCollectionAllOf
extension GatewayAPI {
	public struct ValidatorCollectionAllOf: Codable, Hashable {
		public private(set) var items: [ValidatorCollectionItem]

		public init(items: [ValidatorCollectionItem]) {
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
