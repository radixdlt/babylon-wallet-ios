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

// MARK: - ResourcePreference
public enum ResourcePreference: DummySargon {
	case allowed
	case disallowed
}

// MARK: - ResourcePreferenceUpdate
public enum ResourcePreferenceUpdate: DummySargon {
	case set(value: ResourcePreference)
	case remove
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

// MARK: - NonFungibleLocalId
public enum NonFungibleLocalId: DummySargon {
	public static func from(stringFormat: Any) -> Self {
		panic()
	}

	public static func integer(value: Int) -> Self {
		panic()
	}

	public static func from(stringFormat: String) throws -> Self {
		try Sargon.nonFungibleLocalIdFromStr(string: stringFormat)
	}

	public func toString() throws -> String {
		Sargon.nonFungibleLocalIdAsStr(value: self)
	}

	public func toUserFacingString() -> String {
		do {
			let rawValue = try toString()
			// Just a safety guard. Each NFT Id should be of format <prefix>value<suffix>
			guard rawValue.count >= 3 else {
				loggerGlobal.warning("Invalid nft id: \(rawValue)")
				return rawValue
			}
			// Nothing fancy, just remove the prefix and suffix.
			return String(rawValue.dropLast().dropFirst())
		} catch {
			// Should not happen, just to not throw an error.
			return ""
		}
	}
}

// MARK: - NonFungibleGlobalId
public struct NonFungibleGlobalId: DummySargon {
	public init(nonFungibleGlobalId: String) throws {
		panic()
	}

	public func localId() -> NonFungibleLocalId {
		panic()
	}

	public static func fromParts(
		resourceAddress: ResourceAddress,
		nonFungibleLocalId: NonFungibleLocalId
	) -> Self {
		panic()
	}

	public func asStr() -> String {
		panic()
	}

	public var resourceAddress: ResourceAddress {
		panic()
	}
}

// MARK: - TransactionHash
public typealias TXID = TransactionHash

// MARK: - TransactionHash
public struct TransactionHash: DummySargon {
	public func asStr() -> String {
		panic()
	}

	public func bytes() -> [UInt8] {
		panic()
	}
}

// MARK: - TransactionHeader
public struct TransactionHeader: DummySargon {
	public init(
		networkId: UInt8,
		startEpochInclusive: UInt64,
		endEpochExclusive: UInt64,
		nonce: UInt32,
		notaryPublicKey: Any,
		notaryIsSignatory: Bool,
		tipPercentage: Any
	) {
		panic()
	}

	public var networkId: UInt8 {
		panic()
	}

	public var startEpochInclusive: UInt64 {
		panic()
	}

	public var endEpochExclusive: UInt64 {
		panic()
	}

	public var notaryIsSignatory: Bool {
		panic()
	}

	public var notaryPublicKey: SLIP10.PublicKey {
		panic()
	}

	public var nonce: UInt32 {
		panic()
	}

	public var tipPercentage: Float {
		panic()
	}

	public func description(lookupNetworkName: (NetworkID) throws -> Void) rethrows -> String {
		panic()
	}
}

// MARK: - SignedIntent
public struct SignedIntent: DummySargon {
	public init(intent: TransactionIntent, intentSignatures: [Any]) {
		panic()
	}

	public func intent() -> TransactionIntent {
		panic()
	}

	public func intentSignatures() -> [SignatureWithPublicKey] {
		panic()
	}

	public func signedIntentHash() -> TransactionHash {
		panic()
	}
}

// MARK: - NotarizedTransaction
public struct NotarizedTransaction: DummySargon {
	public func compile() throws -> Data {
		panic()
	}

	public init(signedIntent: Any, notarySignature: Any) throws {
		panic()
	}

	public static func decompile(compiledNotarizedTransaction: Any) -> Self {
		panic()
	}

	public func signedIntent() -> SignedIntent {
		panic()
	}

	public func notarySignature() -> SLIP10.Signature {
		panic()
	}
}

// MARK: - TransactionManifest
public struct TransactionManifest: DummySargon {
	public func extractAddresses() -> [EntityType: [Address]] {
		panic()
	}

	public func instructions() -> Instructions {
		panic()
	}

	public init(instructions: Instructions, blobs: [Data]) {
		panic()
	}

	public func blobs() -> [Data] {
		panic()
	}

	public func summary(networkId: UInt8) -> ManifestSummary {
		panic()
	}

	public func executionSummary(networkId: UInt8, encodedReceipt: Any) -> ExecutionSummary {
		panic()
	}
}

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

// MARK: - ResourceOrNonFungible
public enum ResourceOrNonFungible: DummySargon {
	case resource(ResourceAddress)
	case nonFungible(NonFungibleGlobalId)
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
