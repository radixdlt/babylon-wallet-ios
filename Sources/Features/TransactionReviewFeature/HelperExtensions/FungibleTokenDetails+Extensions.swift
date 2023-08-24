import AssetsFeature
import Foundation
import OnLedgerEntitiesClient
import Prelude
import SharedModels

extension FungibleTokenDetails.State {
	/// Starting out, when we only have the transfer
	init(transfer: TransactionReview.FungibleTransfer) {
		self.init(
			resource: .init(transfer: transfer),
			isXRD: transfer.isXRD
		)
	}

	/// Later on we will have loaded the resource as well
	init(transfer: TransactionReview.FungibleTransfer, resource: OnLedgerEntity.Resource) {
		self.init(
			resource: .init(amount: transfer.amount, resource: resource),
			isXRD: transfer.isXRD
		)
	}
}

extension AccountPortfolio.FungibleResource {
	/// Starting out, when we only have the transfer
	init(transfer: TransactionReview.FungibleTransfer) {
		self.init(
			resourceAddress: transfer.resource,
			amount: transfer.amount,
			name: transfer.name,
			symbol: transfer.symbol,
			iconURL: transfer.thumbnail
		)
	}

	/// Later on we will have loaded the resource, so we have all the values we need
	init(amount: BigDecimal, resource: OnLedgerEntity.Resource) {
		self.init(
			resourceAddress: resource.resourceAddress,
			amount: amount,
			divisibility: resource.divisibility,
			name: resource.name,
			symbol: resource.symbol,
			description: resource.description,
			iconURL: resource.iconURL,
			behaviors: resource.behaviors,
			tags: resource.tags,
			totalSupply: resource.totalSupply
		)
	}
}
