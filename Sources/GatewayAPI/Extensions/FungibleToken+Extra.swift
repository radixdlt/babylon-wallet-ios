import Asset

// MARK: - Convenience
public extension FungibleToken {
	init(
		address: ComponentAddress,
		resourceManagerSubstate substate: ResourceManagerSubstate
	) throws {
		guard substate.resourceType == .fungible else {
			fatalError("bad logic")
		}
		func metadataValueFor(key: String) -> String? {
			substate.metadata.first(where: { $0.key == key })?.value
		}

		self.init(
			address: address,
			divisibility: substate.fungibleDivisibility,
			totalSupplyAttos: try .init(decimalString: substate.totalSupplyAttos).inAttos,
			totalMintedAttos: nil,
			totalBurntAttos: nil,
			// TODO: update when API is ready
			tokenDescription: metadataValueFor(key: "description"),
			name: metadataValueFor(key: "name"),
			symbol: metadataValueFor(key: "symbol"),
			tokenInfoURL: metadataValueFor(key: "url"),
			iconURL: nil
		)
	}
}

public extension Substate {
	var vault: VaultSubstate? {
		guard case let .typeVaultSubstate(vault) = self else {
			return nil
		}
		return vault
	}

	var fungibleResourceAmount: FungibleResourceAmount? {
		vault?.resourceAmount.fungibleResourceAmount
	}

	var nonFungibleResourceAmount: NonFungibleResourceAmount? {
		vault?.resourceAmount.nonFungibleResourceAmount
	}
}

public extension ResourceAmount {
	var fungibleResourceAmount: FungibleResourceAmount? {
		guard case let .typeFungibleResourceAmount(typeFungibleResourceAmount) = self else {
			return nil
		}
		return typeFungibleResourceAmount
	}

	var nonFungibleResourceAmount: NonFungibleResourceAmount? {
		guard case let .typeNonFungibleResourceAmount(typeNonFungibleResourceAmount) = self else {
			return nil
		}
		return typeNonFungibleResourceAmount
	}
}
