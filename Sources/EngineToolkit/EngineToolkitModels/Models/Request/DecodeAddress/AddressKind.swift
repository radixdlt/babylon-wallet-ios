import Foundation

public enum AddressKind: String, Codable, Sendable, Hashable {
	case globalPackage = "GlobalPackage"
	case globalFungibleResource = "GlobalFungibleResource"
	case globalNonFungibleResource = "GlobalNonFungibleResource"
	case globalEpochManager = "GlobalEpochManager"
	case globalValidator = "GlobalValidator"
	case globalClock = "GlobalClock"
	case globalAccessController = "GlobalAccessController"
	case globalAccount = "GlobalAccount"
	case globalIdentity = "GlobalIdentity"
	case globalGenericComponent = "GlobalGenericComponent"

	case globalVirtualEcdsaAccount = "GlobalVirtualEcdsaAccount"
	case globalVirtualEddsaAccount = "GlobalVirtualEddsaAccount"
	case globalVirtualEcdsaIdentity = "GlobalVirtualEcdsaIdentity"
	case globalVirtualEddsaIdentity = "GlobalVirtualEddsaIdentity"

	case internalFungibleVault = "InternalFungibleVault"
	case internalNonFungibleVault = "InternalNonFungibleVault"
	case internalAccount = "InternalAccount"
	case internalKeyValueStore = "InternalKeyValueStore"
	case internalGenericComponent = "InternalGenericComponent"
}
