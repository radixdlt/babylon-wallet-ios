import AssetsFeature
import EngineKit
import EngineToolkit
import Foundation
import OnLedgerEntitiesClient
import Prelude
import SharedModels

extension AccountPortfolio.FungibleResource {
	init(resourceAddress: ResourceAddress, amount: BigDecimal, metadata: [String: MetadataValue?]) {
		self.init(
			resourceAddress: resourceAddress,
			amount: amount,
			name: metadata.name,
			symbol: metadata.symbol,
			description: metadata.description,
			iconURL: metadata.iconURL,
			tags: metadata.tags
		)
	}

	init(amount: BigDecimal, onLedgerEntity: OnLedgerEntity.Resource) {
		self.init(
			resourceAddress: onLedgerEntity.resourceAddress,
			amount: amount,
			divisibility: onLedgerEntity.divisibility,
			name: onLedgerEntity.name,
			symbol: onLedgerEntity.symbol,
			description: onLedgerEntity.description,
			iconURL: onLedgerEntity.iconURL,
			behaviors: onLedgerEntity.behaviors,
			tags: onLedgerEntity.tags,
			totalSupply: onLedgerEntity.totalSupply
		)
	}
}
