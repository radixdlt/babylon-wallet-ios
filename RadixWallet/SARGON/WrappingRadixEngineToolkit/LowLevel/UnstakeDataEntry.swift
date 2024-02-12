import Foundation

// MARK: - UnstakeDataEntry
public struct UnstakeDataEntry: DummySargon {
	public var nonFungibleGlobalId: NonFungibleGlobalId {
		panic()
	}

	public var data: UnstakeData {
		panic()
	}
}

// MARK: - UnstakeData
public struct UnstakeData: DummySargon {
	public var name: String
	public var claimEpoch: Epoch
	public var claimAmount: RETDecimal
}
