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

public typealias TransactionIntent = Intent

// MARK: - Intent
public struct Intent: DummySargon {
	public init(header: Any, manifest: Any, message: Any) {
		panic()
	}

	public func header() -> TransactionHeader {
		panic()
	}

	public func description(lookupNetworkName: (NetworkID) throws -> Void) rethrows -> String {
		panic()
	}

	public func manifest() -> TransactionManifest {
		panic()
	}

	public func intentHash() throws -> TransactionHash {
		panic()
	}

	public func compile() throws -> Data {
		panic()
	}
}

// MARK: - ResourceSpecifier
public enum ResourceSpecifier: DummySargon {
	case amount(
		resourceAddress: RETAddress,
		amount: RETDecimal
	)
	case ids(
		resourceAddress: RETAddress,
		ids: [NonFungibleLocalId]
	)
}

// MARK: - FeeLocks
public enum FeeLocks: DummySargon {
	public var lock: RETDecimal { panic() }
	public var contingentLock: RETDecimal { panic() }
}

// MARK: - FeeSummary
public enum FeeSummary: DummySargon {
	public var executionCost: RETDecimal { panic() }
	public var finalizationCost: RETDecimal { panic() }
	public var storageExpansionCost: RETDecimal { panic() }
	public var royaltyCost: RETDecimal { panic() }
}

// MARK: - MapEntry
public struct MapEntry: DummySargon {
	public let key: ManifestValue
	public let value: ManifestValue
}

// MARK: - ManifestBlobRef
public struct ManifestBlobRef: DummySargon {
	public let value: Hash
}

// MARK: - Hash
public struct Hash: DummySargon {}

// MARK: - RETDecimal
public struct RETDecimal: DummySargon {
	public init(value: String) throws {
		panic()
	}
}

// MARK: - PreciseDecimal
public struct PreciseDecimal: DummySargon {}

// MARK: - NodeId
public enum NodeId: DummySargon {
	public init(address: String) {
		panic()
	}
}

// MARK: - ManifestAddress
public enum ManifestAddress: DummySargon {
	/// Static address, either global or internal, with entity type byte checked.
	/// TODO: prevent direct construction, as in `NonFungibleLocalId`
	case `static`(value: NodeId)
	/// Named address, global only at the moment.
	case named(value: UInt32)
}

// MARK: - ManifestBuilderNamedAddress
public struct ManifestBuilderNamedAddress: DummySargon {
	public let name: String
}

// MARK: - ManifestBuilderAddress
public enum ManifestBuilderAddress: DummySargon {
	case named(value: ManifestBuilderNamedAddress)
	case `static`(value: RETAddress)
}

// MARK: - TrackedValidatorUnstake
public enum TrackedValidatorUnstake: TrackedPoolInteractionStuff {}

// MARK: - TrackedValidatorStake
public enum TrackedValidatorStake: TrackedPoolInteractionStuff {}

// MARK: - TrackedPoolInteractionStuff
public protocol TrackedPoolInteractionStuff: DummySargon {}

extension TrackedPoolInteractionStuff {
	public var validatorAddress: RETAddress {
		panic()
	}

	public var liquidStakeUnitAddress: RETAddress {
		panic()
	}

	public var liquidStakeUnitAmount: RETDecimal {
		get {
			panic()
		}
		set {
			panic()
		}
	}

	public var xrdAmount: RETDecimal {
		get {
			panic()
		}
		set {
			panic()
		}
	}

	public var poolAddress: RETAddress { panic() }
	public var poolUnitsResourceAddress: RETAddress { panic() }
	public var poolUnitsAmount: RETDecimal {
		get {
			panic()
		}
		set {
			panic()
		}
	}

	public var resourcesInInteraction: [String: RETDecimal] {
		get {
			panic()
		}
		set {
			panic()
		}
	}

	public var contributedResources: [String: RETDecimal] {
		get {
			panic()
		}
		set {
			panic()
		}
	}

	public var redeemedResources: [String: RETDecimal] {
		get {
			panic()
		}
		set {
			panic()
		}
	}
}

// MARK: - TrackedPoolContribution
public enum TrackedPoolContribution: TrackedPoolInteractionStuff {}

// MARK: - TrackedPoolRedemption
public enum TrackedPoolRedemption: TrackedPoolInteractionStuff {}

// MARK: - ResourceIndicator
public enum ResourceIndicator: DummySargon {
	case fungible(resourceAddress: RETAddress, indicator: FungibleResourceIndicator)
	case nonFungible(resourceAddress: RETAddress, indicator: NonFungibleResourceIndicator)
}

// MARK: - FungibleResourceIndicator
public enum FungibleResourceIndicator: DummySargon {
	case guaranteed(amount: PredictedDecimal)
	case predicted(PredictedDecimal)
}

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
}

// MARK: - ReservedInstruction
public enum ReservedInstruction: DummySargon {}

// MARK: - DummySargonPublicKey
public enum DummySargonPublicKey: DummySargon {}

// MARK: - MetadataValue
public enum MetadataValue: DummySargon {
	case stringValue(value: String)
	case urlValue(value: String)
	case publicKeyHashArrayValue(value: [RETPublicKeyHash])
	case stringArrayValue(value: [String])
}

// MARK: - RETPublicKeyHash
public struct RETPublicKeyHash: DeprecatedDummySargon {
	public static func secp256k1(value: Any) -> Self {
		panic()
	}

	public static func ed25519(value: Any) -> Self {
		panic()
	}

	public init(hashing: Any) throws {
		panic()
	}
}

// MARK: - ManifestSummary
public struct ManifestSummary: DummySargon {
	public var accountsDepositedInto: [RETAddress] {
		panic()
	}

	public var accountsWithdrawnFrom: [RETAddress] {
		panic()
	}

	public var accountsRequiringAuth: [RETAddress] {
		panic()
	}

	public var identitiesRequiringAuth: [RETAddress] {
		panic()
	}
}

// MARK: - DummySargonAddress
public protocol DummySargonAddress: DummySargon, AddressProtocol {
	init(validatingAddress: Any) throws
}

// MARK: - AccessRule
public enum AccessRule: DummySargon {}

// MARK: - OwnerRole
public enum OwnerRole: DummySargon {
	case none
	case fixed(value: AccessRule)
	case updatable(value: AccessRule)
}

// MARK: - ResourceManagerRole
public struct ResourceManagerRole: DummySargon {
	public let role: AccessRule?
	public let roleUpdater: AccessRule?
}

public typealias MetadataInit = [String: MetadataInitEntry]

// MARK: - MetadataInitEntry
public struct MetadataInitEntry: DummySargon {
	public let value: MetadataValue
	public let lock: Bool
}

// MARK: - ManifestBuilderAddressReservation
public struct ManifestBuilderAddressReservation: DummySargon {
	public let name: String
}

// MARK: - MetadataModuleConfig
public struct MetadataModuleConfig: DummySargon {
	public let `init`: MetadataInit
	public let roles: [String: AccessRule?]
}

// MARK: - FungibleResourceRoles
public struct FungibleResourceRoles: DummySargon {
	public let mintRoles: ResourceManagerRole?
	public let burnRoles: ResourceManagerRole?
	public let freezeRoles: ResourceManagerRole?
	public let recallRoles: ResourceManagerRole?
	public let withdrawRoles: ResourceManagerRole?
	public let depositRoles: ResourceManagerRole?
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

	public func intoManifestBuilderAddress() -> ManifestBuilderAddress {
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
		resourceAddress: RETAddress,
		nonFungibleLocalId: NonFungibleLocalId
	) -> Self {
		panic()
	}

	public func asStr() -> String {
		panic()
	}

	public func resourceAddress() -> RETAddress {
		panic()
	}
}

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

	public func intentSignatures() -> [RETSignatureWithPublicKey] {
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

	public func notarySignature() -> RETSignature {
		panic()
	}
}

// MARK: - TransactionManifest
public struct TransactionManifest: DummySargon {
	public func extractAddresses() -> [EntityType: [RETAddress]] {
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

	public func withInstructionAdded(_ guarantee: Any, at: Int) throws -> Self {
		panic()
	}

	public func setAccountType(from: String, type: String) -> Self {
		panic()
	}

	public func withLockFeeCallMethodAdded(address: AccountAddress, fee: RETDecimal) throws -> Self {
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

// MARK: - DetailedManifestClass
public enum DetailedManifestClass: DummySargon {
	case general, transfer
	case validatorClaim([RETAddress], Bool)
	case validatorStake(validatorAddresses: [RETAddress], validatorStakes: [TrackedValidatorStake])
	case validatorUnstake(validatorAddresses: [RETAddress], validatorUnstakes: [TrackedValidatorUnstake], claimsNonFungibleData: [UnstakeDataEntry])
	case accountDepositSettingsUpdate(
		resourcePreferencesUpdates: [String: [String: ResourcePreferenceUpdate]],
		depositModeUpdates: [String: AccountDefaultDepositRule],
		authorizedDepositorsAdded:
		[String: [ResourceOrNonFungible]],
		authorizedDepositorsRemoved:
		[String: [ResourceOrNonFungible]]
	)

	case poolContribution(poolAddresses: [RETAddress], poolContributions: [TrackedPoolContribution])
	case poolRedemption(poolAddresses: [RETAddress], poolContributions: [TrackedPoolRedemption])
}

// MARK: - ExecutionSummary
public struct ExecutionSummary: DummySargon {
	public struct NewEntities: DummySargon {
		public var metadata: [String: [String: MetadataValue?]] {
			panic()
		}

		public var componentAddresses: [RETAddress] {
			panic()
		}

		public var resourceAddresses: [RETAddress] {
			panic()
		}

		public var packageAddresses: [RETAddress] {
			panic()
		}
	}

	public var detailedClassification: [DetailedManifestClass] {
		panic()
	}

	public var newEntities: NewEntities {
		panic()
	}

	public var accountWithdraws: [String: [ResourceIndicator]] {
		panic()
	}

	public var accountDeposits: [String: [ResourceIndicator]] {
		panic()
	}

	public var reservedInstructions: [ReservedInstruction] {
		panic()
	}

	public var newlyCreatedNonFungibles: [NonFungibleGlobalId] {
		panic()
	}

	public var presentedProofs: [RETAddress] {
		panic()
	}

	public var encounteredEntities: [RETAddress] {
		panic()
	}

	public var feeLocks: FeeLocks { panic() }

	public var feeSummary: FeeSummary { panic() }
}

// MARK: - ResourceOrNonFungible
public enum ResourceOrNonFungible: DummySargon {
	case resource(RETAddress)
	case nonFungible(NonFungibleGlobalId)
}

// MARK: - KnownAddresses
public struct KnownAddresses: DummySargon {
	public struct ResourceAddresses: DummySargon {
		public var xrd: RETAddress {
			panic()
		}
	}

	public struct PackageAddresses: DummySargon {}
	public struct ComponentAddresses: DummySargon {}
	public var resourceAddresses: ResourceAddresses
//	public var package_addresses: PackageAddresses,
//	public var component_addresses: ComponentAddresses,
}

// MARK: - Instruction
public enum Instruction: DummySargon {
	case assertWorktopContains(resourceAddress: RETAddress, amount: RETDecimal)
	case callMethod(address: ManifestAddress, methodName: String, args: ManifestValue)
}

// MARK: - Instructions
public struct Instructions: DummySargon {
	public func asStr() -> String {
		panic()
	}

	public func networkId() -> UInt8 {
		panic()
	}

	public static func fromString(string: Any, networkId: UInt8) -> Self {
		panic()
	}

	public func instructionsList() -> [Instruction] {
		panic()
	}

	public static func fromInstructions(instructions: [Instruction], networkId: Any) throws -> Self {
		panic()
	}
}

// MARK: - Message
public enum Message: DummySargon {
	public enum PlaintextMessage: DummySargon {
		public init(mimeType: String, message: PlaintextMessageInner) {
			panic()
		}

		public enum PlaintextMessageInner: DummySargon {
			case str(value: String)
		}

		public var message: PlaintextMessageInner {
			panic()
		}
	}

	static var none: Self { panic() }
	case plainText(value: PlaintextMessage)
	static func encrypted(value: Any) -> Self { panic() }
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
}

// MARK: - AccountDefaultDepositRule
public enum AccountDefaultDepositRule: DeprecatedDummySargon {
	case accept, reject, allowExisting
}

// MARK: - ManifestBuilderValue
public enum ManifestBuilderValue: DeprecatedDummySargon {
	public static func enumValue(discriminator: Any, fields: [ManifestValue]) -> Self {
		panic()
	}

	public static func addressValue(value: Any) -> Self {
		panic()
	}

	public static func `static`(value: Any) -> Self {
		panic()
	}

	public static func tupleValue(fields: [ManifestValue]) -> Self {
		panic()
	}
}

// MARK: - ManifestValue
public enum ManifestValue: DeprecatedDummySargon {
	case enumValue(discriminator: UInt8, fields: [ManifestValue])
	case addressValue(value: ManifestBuilderAddress)
	case tupleValue(fields: [ManifestValue])
	case decimalValue(value: RETDecimal)
	case nonFungibleLocalIdValue(value: NonFungibleLocalId)

	case boolValue(value: Any)
	case i8Value(value: Any)
	case i16Value(value: Any)
	case i32Value(value: Any)
	case i64Value(value: Any)
	case i128Value(value: Any)
	case u8Value(value: Any)
	case u16Value(value: Any)
	case u32Value(value: Any)
	case u64Value(value: Any)
	case u128Value(value: Any)
	case stringValue(value: Any)
	case arrayValue(elementValueKind: Any, elements: Any)
	case mapValue(keyValueKind: Any, valueValueKind: Any, entries: Any)
	case bucketValue(value: Any)
	case proofValue(value: Any)
	case expressionValue(value: Any)
	case blobValue(value: Any)
	case preciseDecimalValue(value: Any)
	case addressReservationValue(value: Any)
}

// MARK: - ManifestBuilderBucket
public enum ManifestBuilderBucket: DeprecatedDummySargon {}

// MARK: - ResolvableArguments
public enum ResolvableArguments: DummySargon {
	public static func addressValue(value: Any) -> Self {
		panic()
	}
}

// MARK: - ManifestBuilder
public enum ManifestBuilder: DeprecatedDummySargon {
	public init() {
		panic()
	}

	public func setOwnerKeys(from: Any, ownerKeyHashes: [Any]) throws -> ManifestBuilder {
		panic()
	}

	public func build(networkId: Any) -> TransactionManifest {
		panic()
	}

	public static func manifestForCreateFungibleToken(
		account: Any,
		networkID: Any
	) throws -> TransactionManifest {
		panic()
	}

	public static func withdrawAmount(
		_ args: Any...
	) throws -> TransactionManifest {
		panic()
	}

	public static func takeFromWorktop(
		_ args: Any...
	) throws -> TransactionManifest {
		panic()
	}

	public static func withdrawTokens(
		_ args: Any...
	) throws -> ManifestBuilder.InstructionsChain.Instruction {
		panic()
	}

	public static func stakeClaimsManifest(
		accountAddress: AccountAddress,
		stakeClaims: [Any]
	) throws -> TransactionManifest {
		panic()
	}

	public static func takeNonFungiblesFromWorktop(
		_ args: Any...
	) throws -> TransactionManifest {
		panic()
	}

	public static func accountDeposit(_ args: Any...) throws -> ManifestBuilder.InstructionsChain.Instruction {
		panic()
	}

	public static func manifestForFaucet(
		includeLockFeeInstruction: Any,
		networkID: Any,
		componentAddress: Any
	) throws -> TransactionManifest {
		panic()
	}

	public static func manifestForCreateNonFungibleToken(
		account: Any,
		networkID: Any
	) throws -> TransactionManifest {
		panic()
	}

	public func callMethod(
		address: Any,
		methodName: Any,
		args: [ManifestBuilderValue]
	) throws -> ManifestBuilder {
		panic()
	}

	public static func setDefaultDepositorRule(
		accountAddress: Any
	) throws -> TransactionManifest {
		panic()
	}

	public static func setResourcePreference(
		_ args: Any...
	) -> TransactionManifest {
		panic()
	}

	public static func setDefaultDepositorRule(
		_ args: Any...
	) -> TransactionManifest {
		panic()
	}

	public static func removeResourcePreference(
		_ args: Any...
	) -> TransactionManifest {
		panic()
	}

	public static func removeAuthorizedDepositor(
		_ args: Any...
	) -> TransactionManifest {
		panic()
	}

	public static func addAuthorizedDepositor(
		_ args: Any...
	) -> TransactionManifest {
		panic()
	}

	public static func manifestForCreateMultipleFungibleTokens(
		account: Any,
		networkID: Any
	) -> TransactionManifest {
		panic()
	}

	public static func manifestForCreateMultipleNonFungibleTokens(
		account: Any,
		networkID: Any
	) throws -> TransactionManifest {
		panic()
	}
}

// MARK: - OlympiaNetwork
public enum OlympiaNetwork: DummySargon {
	case mainnet
}

// MARK: - BuildInformation
public struct BuildInformation: DummySargon {
	public let version: String
}

public func deriveVirtualAccountAddressFromPublicKey(
	publicKey: Any,
	networkId: Any
) throws -> AccountAddress {
	panic()
}

public func deriveVirtualIdentityAddressFromPublicKey(
	publicKey: Any,
	networkId: Any
) throws -> IdentityAddress {
	panic()
}

public func deriveOlympiaAccountAddressFromPublicKey(
	publicKey: Any,
	olympiaNetwork: OlympiaNetwork
) throws -> AccountAddress {
	panic()
}

public func knownAddresses(
	networkId: UInt8
) -> KnownAddresses {
	panic()
}

public func nonFungibleLocalIdAsStr(value: NonFungibleLocalId) -> String {
	panic()
}

public func nonFungibleLocalIdFromStr(string: String) throws -> NonFungibleLocalId {
	panic()
}
