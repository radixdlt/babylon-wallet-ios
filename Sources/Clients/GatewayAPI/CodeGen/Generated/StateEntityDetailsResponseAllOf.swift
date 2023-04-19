import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.StateEntityDetailsResponseAllOf")
public typealias StateEntityDetailsResponseAllOf = GatewayAPI.StateEntityDetailsResponseAllOf

// MARK: - GatewayAPI.StateEntityDetailsResponseAllOf
extension GatewayAPI {
	public struct StateEntityDetailsResponseAllOf: Codable, Hashable {
		public private(set) var items: [StateEntityDetailsResponseItem]

		public init(items: [StateEntityDetailsResponseItem]) {
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
