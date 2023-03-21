import Foundation

public enum AddressKind: String, Codable, Sendable, Hashable {
	case fungibleResource = "FungibleResource"
	case nonFungibleResource = "NonFungibleResource"

	case package = "Package"

	case accountComponent = "AccountComponent"
	case normalComponent = "NormalComponent"
}
