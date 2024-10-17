
extension OnLedgerEntity.NonFungibleToken {
	init(resourceAddress: ResourceAddress, nftID: NonFungibleLocalId, nftData: NFTData?) {
		self.init(
			id: NonFungibleGlobalID(
				resourceAddress: resourceAddress,
				nonFungibleLocalId: nftID
			),
			data: nftData
		)
	}
}

extension OnLedgerEntity.Resource {
	init(resourceAddress: ResourceAddress, metadata: OnLedgerEntity.Metadata) {
		self.init(
			resourceAddress: resourceAddress,
			atLedgerState: .init(version: 0, epoch: 0),
			divisibility: nil,
			behaviors: [],
			totalSupply: nil,
			metadata: metadata
		)
	}
}
