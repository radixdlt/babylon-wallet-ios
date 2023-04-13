import Foundation

public enum AddressKind: String, Codable, Sendable, Hashable {
	case fungibleResource = "FungibleResource"
	case nonFungibleResource = "NonFungibleResource"

	case package = "Package"

	case accountComponent = "AccountComponent"
	case normalComponent = "NormalComponent"
	case secp256k1VirtualAccountComponent = "EcdsaSecp256k1VirtualAccountComponent"
	case ed25519VirtualAccountComponent = "EddsaEd25519VirtualAccountComponent"
	case secp256k1VirtualIdentityComponent = "EcdsaSecp256k1VirtualIdentityComponent"
	case ed25519VirtualIdentityComponent = "EddsaEd25519VirtualIdentityComponent"

	case identityComponent = "IdentityComponent"
	case epochManager = "EpochManager"
	case validator = "Validator"
	case clock = "Clock"
	case accessControllerComponent = "AccessControllerComponent"
}
