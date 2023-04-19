import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

@available(*, deprecated, renamed: "GatewayAPI.StateEntityDetailsResponseItemDetailsType")
public typealias StateEntityDetailsResponseItemDetailsType = GatewayAPI.StateEntityDetailsResponseItemDetailsType

// MARK: - GatewayAPI.StateEntityDetailsResponseItemDetailsType
extension GatewayAPI {
	public enum StateEntityDetailsResponseItemDetailsType: String, Codable, CaseIterable {
		case fungibleResource = "FungibleResource"
		case nonFungibleResource = "NonFungibleResource"
		case fungibleVault = "FungibleVault"
		case nonFungibleVault = "NonFungibleVault"
		case package = "Package"
		case component = "Component"
	}
}
