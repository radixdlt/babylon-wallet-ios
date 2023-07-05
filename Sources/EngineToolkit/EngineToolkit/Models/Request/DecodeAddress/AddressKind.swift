import Foundation

public enum AddressKind: String, Codable, Sendable, Hashable, CaseIterable {
	case globalPackage = "GlobalPackage"
	case globalConsensusManager = "GlobalConsensusManager"
	case globalValidator = "GlobalValidator"
	case globalGenericComponent = "GlobalGenericComponent"
	case globalAccount = "GlobalAccount"
	case globalIdentity = "GlobalIdentity"
	case globalAccessController = "GlobalAccessController"
	case globalVirtualSecp256k1Account = "GlobalVirtualSecp256k1Account"
	case globalVirtualSecp256k1Identity = "GlobalVirtualSecp256k1Identity"
	case globalVirtualEd25519Account = "GlobalVirtualEd25519Account"
	case globalVirtualEd25519Identity = "GlobalVirtualEd25519Identity"
	case globalFungibleResourceManager = "GlobalFungibleResourceManager"
	case internalFungibleVault = "InternalFungibleVault"
	case globalNonFungibleResourceManager = "GlobalNonFungibleResourceManager"
	case internalNonFungibleVault = "InternalNonFungibleVault"
	case internalGenericComponent = "InternalGenericComponent"
	case internalAccount = "InternalAccount"
	case internalKeyValueStore = "InternalKeyValueStore"
}
