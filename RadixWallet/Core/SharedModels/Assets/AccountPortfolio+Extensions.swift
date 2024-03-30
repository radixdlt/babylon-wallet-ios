
extension OnLedgerEntity.NonFungibleToken {
	public init(resourceAddress: ResourceAddress, nftID: NonFungibleLocalId, nftData: NFTData?) throws {
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
	public init(resourceAddress: ResourceAddress, metadata: OnLedgerEntity.Metadata) {
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
