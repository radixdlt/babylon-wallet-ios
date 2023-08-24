import AssetsFeature
import EngineToolkit
import Foundation
import OnLedgerEntitiesClient
import Prelude
import SharedModels

extension NonFungibleTokenDetails.State {
	init(
		transfer: TransactionReview.NonFungibleTransfer,
		metadata: [String: MetadataValue?]? = nil,
		resource: OnLedgerEntity.Resource? = nil
	) throws {
		try self.init(
			token: .init(transfer: transfer, resource: resource),
			resource: .init(transfer: transfer, metadata: metadata, resource: resource)
		)
	}
}

extension AccountPortfolio.NonFungibleResource {
	init(
		transfer: TransactionReview.NonFungibleTransfer,
		metadata: [String: MetadataValue?]?,
		resource: OnLedgerEntity.Resource?
	) {
		self.init(
			resourceAddress: transfer.resource,
			name: metadata?.name ?? resource?.name ?? transfer.resourceName,
			description: metadata?.description ?? resource?.description,
			iconURL: resource?.iconURL ?? metadata?.iconURL ?? transfer.resourceImage,
			behaviors: resource?.behaviors ?? [],
			tags: resource?.tags ?? [],
			tokens: [],
			totalSupply: resource?.totalSupply
		)
	}
}

extension AccountPortfolio.NonFungibleResource.NonFungibleToken {
	init(
		transfer: TransactionReview.NonFungibleTransfer,
		resource: OnLedgerEntity.Resource?
	) throws {
		try self.init(
			id: transfer.nonFungibleGlobalId(),
			name: transfer.tokenName,
			description: nil, // FIXME: FIND
			keyImageURL: nil, // FIXME: FIND
			metadata: [], // FIXME: FIND
			stakeClaimAmount: nil,
			canBeClaimed: false // FIXME: FIND
		)
	}
}

extension TransactionReview.NonFungibleTransfer {
	func nonFungibleGlobalId() throws -> NonFungibleGlobalId {
		try .fromParts(
			resourceAddress: resource.intoEngine(),
			nonFungibleLocalId: nonFungibleLocalIdFromStr(string: tokenID)
		)
	}
}
