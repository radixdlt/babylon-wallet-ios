import EngineToolkit

extension EntityType {
	public var isResourcePool: Bool {
		switch self {
		case .globalOneResourcePool, .globalTwoResourcePool, .globalMultiResourcePool:
			true
		case .globalPackage, .globalFungibleResourceManager, .globalNonFungibleResourceManager, .globalConsensusManager,
		     .globalValidator, .globalAccessController, .globalAccount,
		     .globalIdentity, .globalGenericComponent, .globalVirtualSecp256k1Account,
		     .globalVirtualEd25519Account, .globalVirtualSecp256k1Identity, .globalVirtualEd25519Identity,
		     .globalTransactionTracker, .internalFungibleVault, .internalNonFungibleVault,
		     .internalGenericComponent, .internalKeyValueStore:
			false
		}
	}
}
