import Foundation

// MARK: - UnstakeDataEntry
public struct UnstakeDataEntry: DummySargon {
	public var nonFungibleGlobalId: NonFungibleGlobalId {
		sargon()
	}

	public var data: UnstakeData {
		sargon()
	}
}

// MARK: - UnstakeData
public struct UnstakeData: DummySargon {
	public var claimEpoch: Epoch
	public var claimAmount: RETDecimal
}
