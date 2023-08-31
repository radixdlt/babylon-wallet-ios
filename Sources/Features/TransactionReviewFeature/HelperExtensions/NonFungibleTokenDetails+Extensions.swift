import AssetsFeature
import EngineKit
import EngineToolkit
import Foundation
import GatewayAPI
import OnLedgerEntitiesClient
import Prelude
import SharedModels

extension AccountPortfolio.NonFungibleResource {
	init(resourceAddress: ResourceAddress, metadata: [String: MetadataValue?]) {
		self.init(
			resourceAddress: resourceAddress,
			name: metadata.name,
			description: metadata.description,
			iconURL: metadata.iconURL,
			tags: metadata.tags
		)
	}

	init(onLedgerEntity: OnLedgerEntity.Resource, tokens: IdentifiedArrayOf<NonFungibleToken> = []) {
		self.init(
			resourceAddress: onLedgerEntity.resourceAddress,
			name: onLedgerEntity.name,
			description: onLedgerEntity.description,
			iconURL: onLedgerEntity.iconURL,
			behaviors: onLedgerEntity.behaviors,
			tags: onLedgerEntity.tags,
			tokens: tokens,
			totalSupply: onLedgerEntity.totalSupply
		)
	}
}

extension AccountPortfolio.NonFungibleResource.NonFungibleToken {
	init(resourceAddress: ResourceAddress, nftResponseItem: GatewayAPI.StateNonFungibleDetailsResponseItem) throws {
		try self.init(
			id: .fromParts(
				resourceAddress: resourceAddress.intoEngine(),
				nonFungibleLocalId: .from(stringFormat: nftResponseItem.nonFungibleId)
			),
			name: nftResponseItem.details.name,
			description: nftResponseItem.details.description,
			keyImageURL: nftResponseItem.details.keyImageURL,
			metadata: [], // FIXME: Find?
			stakeClaimAmount: nil,
			canBeClaimed: false // FIXME: Find?
		)
	}
}
