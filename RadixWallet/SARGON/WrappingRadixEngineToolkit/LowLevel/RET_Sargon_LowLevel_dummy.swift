import Foundation

// MARK: - DummySargon
public protocol DummySargon: Sendable, Equatable, Hashable, Codable, Identifiable, CustomStringConvertible {}

// MARK: - DeprecatedDummySargon
@available(*, deprecated, message: "Remove completely")
public protocol DeprecatedDummySargon: DummySargon {}

public func panic(line: UInt = #line) -> Never {
	fatalError("DummySargon: \(line)")
}

public func sargon(line: UInt = #line) -> Never {
	fatalError("FIX THIS part of Sargon migration: \(line)")
}

extension DummySargon {
	public typealias ID = UUID
	public var id: ID {
		panic()
	}

	public static func == (lhs: Self, rhs: Self) -> Bool {
		panic()
	}

	public func hash(into hasher: inout Hasher) {
		panic()
	}

	public var description: String {
		panic()
	}

	public func encode(to encoder: Encoder) throws {
		panic()
	}

	public init(from decoder: Decoder) throws {
		panic()
	}

	public func asStr() -> String {
		panic()
	}
}

// MARK: - RadixEngineToolkitError
public struct RadixEngineToolkitError: DummySargon {}

// MARK: - AbstractPredictedValue
public struct AbstractPredictedValue<Value>: DummySargon where Value: Sendable & Hashable {
	public let value: Value
	public let instructionIndex: UInt64
}

public typealias PredictedDecimal = AbstractPredictedValue<RETDecimal>
public typealias PredictedNonFungibleIds = AbstractPredictedValue<[NonFungibleLocalId]>

public func + (lhs: PredictedDecimal, rhs: PredictedDecimal) -> PredictedDecimal {
	panic()
}

// MARK: - DummySargonPublicKey
public enum DummySargonPublicKey: DummySargon {}

// MARK: - DummySargonAddress
public protocol DummySargonAddress: DummySargon, AddressProtocol {
	init(validatingAddress: Any) throws
}

extension DummySargonAddress {
	public init(address: Any, decodedKind: Any) {
		panic()
	}

	public init(validatingAddress: Any) throws {
		panic()
	}

	public var decodedKind: EntityType {
		panic()
	}

	public func asStr() -> String {
		panic()
	}

	public init(address: Any) {
		panic()
	}

	public var address: String { panic() }
	public func networkId() -> UInt8 {
		panic()
	}
}

// MARK: - EntityType
public enum EntityType: DeprecatedDummySargon {
	case globalPackage
	case globalFungibleResourceManager
	case globalNonFungibleResourceManager
	case globalConsensusManager
	case globalValidator
	case globalAccessController
	case globalAccount
	case globalIdentity
	case globalGenericComponent
	case globalVirtualSecp256k1Account
	case globalVirtualEd25519Account
	case globalVirtualSecp256k1Identity
	case globalVirtualEd25519Identity
	case globalOneResourcePool
	case globalTwoResourcePool
	case globalMultiResourcePool
	case globalTransactionTracker
	case internalFungibleVault
	case internalNonFungibleVault
	case internalGenericComponent
	case internalKeyValueStore

	public var isResourcePool: Bool {
		panic()
	}
}

// MARK: - AccountDefaultDepositRule
public enum AccountDefaultDepositRule: DeprecatedDummySargon {
	case accept, reject, allowExisting
}

// MARK: - BuildInformation
public struct BuildInformation: DummySargon {
	public let version: String
}
