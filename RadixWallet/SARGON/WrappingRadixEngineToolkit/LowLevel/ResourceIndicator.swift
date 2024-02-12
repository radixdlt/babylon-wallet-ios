import Foundation

// MARK: - ResourceIndicator
public enum ResourceIndicator: DummySargon {
	case fungible(resourceAddress: ResourceAddress, indicator: FungibleResourceIndicator)
	case nonFungible(resourceAddress: ResourceAddress, indicator: NonFungibleResourceIndicator)

	public var resourceAddress: ResourceAddress {
		switch self {
		case let .fungible(address, _):
			address
		case let .nonFungible(address, _):
			address
		}
	}
}

// MARK: - AbstractPredictedValue
public struct AbstractPredictedValue<Value>: DummySargon where Value: Sendable & Hashable {
	public let value: Value
	public let instructionIndex: UInt64
}

public typealias PredictedDecimal = AbstractPredictedValue<RETDecimal>
public typealias PredictedNonFungibleIds = AbstractPredictedValue<[NonFungibleLocalId]>

public func + (lhs: PredictedDecimal, rhs: PredictedDecimal) -> PredictedDecimal {
	sargon()
}

// MARK: - FungibleResourceIndicator
public enum FungibleResourceIndicator: DummySargon {
	case guaranteed(amount: PredictedDecimal)
	case predicted(PredictedDecimal)
	public var amount: RETDecimal {
		sargon()
	}
}

// MARK: - NonFungibleResourceIndicator
public enum NonFungibleResourceIndicator: DummySargon {
	case byAll(
		predictedAmount: PredictedDecimal,
		predictedIds: PredictedNonFungibleIds
	)
	case byAmount(
		amount: PredictedDecimal,
		predictedIds: PredictedNonFungibleIds
	)
	case byIds(ids: [NonFungibleLocalId])

	public var ids: [NonFungibleLocalId] {
		switch self {
		case let .byIds(ids):
			ids
		case let .byAll(_, ids), let .byAmount(_, ids):
			ids.value
		}
	}
}
