import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.StateEntityDetailsResponseFungibleVaultDetails")
public typealias StateEntityDetailsResponseFungibleVaultDetails = GatewayAPI.StateEntityDetailsResponseFungibleVaultDetails

// MARK: - GatewayAPI.StateEntityDetailsResponseFungibleVaultDetails
extension GatewayAPI {
	public struct StateEntityDetailsResponseFungibleVaultDetails: Codable, Hashable {
		public private(set) var type: StateEntityDetailsResponseItemDetailsType

		public init(type: StateEntityDetailsResponseItemDetailsType) {
			self.type = type
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case type
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(type, forKey: .type)
		}
	}
}
