import AssetsFeature
import EngineToolkit
import Foundation
import OnLedgerEntitiesClient
import Prelude
import SharedModels

extension NonFungibleTokenDetails.State {
	/// Starting out, we only have the transfer
	init(transfer: TransactionReview.NonFungibleTransfer) throws {
		try self.init(
			token: .init(transfer: transfer),
			resource: .init(transfer: transfer)
		)
	}

	/// Later on we will have loaded the resource as well
	init(transfer: TransactionReview.NonFungibleTransfer, resource: OnLedgerEntity.Resource) throws {
		try self.init(
			token: .init(transfer: transfer),
			resource: .init(resource: resource)
		)
	}
}

extension AccountPortfolio.NonFungibleResource {
	/// Starting out, when we only have the transfer
	init(transfer: TransactionReview.NonFungibleTransfer) {
		self.init(
			resourceAddress: transfer.resource,
			name: transfer.resourceName,
			iconURL: transfer.resourceImage,
			tokens: (try? NonFungibleToken(transfer: transfer)).map { [$0] } ?? []
		)
	}

	/// Later on we will have loaded the resource, so we have all the values we need
	init(resource: OnLedgerEntity.Resource) {
		self.init(
			resourceAddress: resource.resourceAddress,
			name: resource.name,
			description: resource.description,
			iconURL: resource.iconURL,
			behaviors: resource.behaviors,
			tags: resource.tags,
			tokens: [],
			totalSupply: resource.totalSupply
		)
	}
}

extension AccountPortfolio.NonFungibleResource.NonFungibleToken {
	/// Starting out, when we only have the transfer
	init(transfer: TransactionReview.NonFungibleTransfer) throws {
		try self.init(
			id: transfer.nonFungibleGlobalId(),
			name: transfer.tokenName
		)
	}

	/// Later on we will have loaded the resource, so we have all the values we need
	init(transfer: TransactionReview.NonFungibleTransfer, resource: OnLedgerEntity.Resource) throws {
		fatalError()
//		self.init(
//			id: try .init(transfer: transfer),
//			name: resource.name,
//			description: resource.description,
//			keyImageURL: transfer.,
//			metadata: <#T##[AccountPortfolio.Metadata]#>,
//			stakeClaimAmount: <#T##BigDecimal?#>,
//			canBeClaimed: <#T##Bool#>
//		)
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
