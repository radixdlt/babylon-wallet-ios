import AssetsFeature
import EngineKit
import EngineToolkit
import Foundation
import OnLedgerEntitiesClient
import Prelude
import SharedModels

extension FungibleTokenDetails.State {
	init(
		transfer: TransactionReview.FungibleTransfer,
		metadata: [String: MetadataValue?]? = nil,
		resource: OnLedgerEntity.Resource? = nil
	) {
		self.init(
			resource: .init(transfer: transfer, metadata: metadata, resource: resource),
			isXRD: transfer.isXRD
		)
	}
}

extension AccountPortfolio.FungibleResource {
	init(
		transfer: TransactionReview.FungibleTransfer,
		metadata: [String: MetadataValue?]?,
		resource: OnLedgerEntity.Resource? = nil
	) {
		self.init(
			resourceAddress: transfer.resource,
			amount: transfer.amount,
			divisibility: resource?.divisibility,
			name: resource?.name ?? transfer.name,
			symbol: resource?.symbol ?? transfer.symbol,
			description: metadata?.description ?? resource?.description,
			iconURL: resource?.iconURL ?? metadata?.iconURL ?? transfer.thumbnail,
			behaviors: resource?.behaviors ?? [],
			tags: resource?.tags ?? [],
			totalSupply: resource?.totalSupply
		)
	}
}
