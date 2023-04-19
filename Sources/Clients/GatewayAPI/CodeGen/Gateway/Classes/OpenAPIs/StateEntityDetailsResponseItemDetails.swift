import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.StateEntityDetailsResponseItemDetails")
public typealias StateEntityDetailsResponseItemDetails = GatewayAPI.StateEntityDetailsResponseItemDetails

// MARK: - GatewayAPI.StateEntityDetailsResponseItemDetails
extension GatewayAPI {
	public enum StateEntityDetailsResponseItemDetails: Codable, Hashable {
		case fungibleResource(StateEntityDetailsResponseFungibleResourceDetails)
		case nonFungibleResource(StateEntityDetailsResponseNonFungibleResourceDetails)
		case fungibleVault(StateEntityDetailsResponseFungibleVaultDetails)
		case nonFungibleVault(StateEntityDetailsResponseNonFungibleVaultDetails)
		case package(StateEntityDetailsResponsePackageDetails)
		case component(StateEntityDetailsResponseComponentDetails)

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case type
		}

		public init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodingKeys.self)
			let type = try container.decode(StateEntityDetailsResponseItemDetailsType.self, forKey: .type)

			switch type {
			case .fungibleResource:
				self = try .fungibleResource(.init(from: decoder))
			case .nonFungibleResource:
				self = try .nonFungibleResource(.init(from: decoder))
			case .fungibleVault:
				self = try .fungibleVault(.init(from: decoder))
			case .nonFungibleVault:
				self = try .nonFungibleVault(.init(from: decoder))
			case .package:
				self = try .package(.init(from: decoder))
			case .component:
				self = try .component(.init(from: decoder))
			}
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			switch self {
			case let .fungibleResource(item):
				try item.encode(to: encoder)
			case let .nonFungibleResource(item):
				try item.encode(to: encoder)
			case let .fungibleVault(item):
				try item.encode(to: encoder)
			case let .nonFungibleVault(item):
				try item.encode(to: encoder)
			case let .package(item):
				try item.encode(to: encoder)
			case let .component(item):
				try item.encode(to: encoder)
			}
		}
	}
}
