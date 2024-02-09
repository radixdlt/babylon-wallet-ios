import Foundation

// MARK: - DummySargon
public protocol DummySargon: Sendable, Equatable, Hashable, Codable, Identifiable, CustomStringConvertible {}

// MARK: - DeprecatedDummySargon
@available(*, deprecated, message: "Remove completely")
public protocol DeprecatedDummySargon: DummySargon {}
public func panic(line: UInt = #line) -> Never {
	fatalError("DummySargon: \(line)")
}

extension DummySargon {
	public typealias ID = UUID
	public var id: ID {
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
}

// MARK: - RETDecimal
public final class RETDecimal: DummySargon {}

// MARK: - PreciseDecimal
public final class PreciseDecimal: DummySargon {}

// MARK: - NodeId
public enum NodeId: DummySargon {}

// MARK: - ManifestAddress
public enum ManifestAddress {
	/// Static address, either global or internal, with entity type byte checked.
	/// TODO: prevent direct construction, as in `NonFungibleLocalId`
	case `static`(value: NodeId)
	/// Named address, global only at the moment.
	case named(value: UInt32)
}

// MARK: - TrackedValidatorUnstake
public enum TrackedValidatorUnstake: TrackedPoolInteractionStuff {}

// MARK: - TrackedValidatorStake
public enum TrackedValidatorStake: TrackedPoolInteractionStuff {}

// MARK: - TrackedPoolInteractionStuff
public protocol TrackedPoolInteractionStuff: DummySargon {}

extension TrackedPoolInteractionStuff {
	public var validatorAddress: EngineToolkitAddress {
		panic()
	}

	public var liquidStakeUnitAddress: EngineToolkitAddress {
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

	public var poolAddress: EngineToolkitAddress { panic() }
	public var poolUnitsResourceAddress: EngineToolkitAddress { panic() }
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

	public mutating func add(_ other: Self) {
		panic()
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
	case fungible(resourceAddress: ResourceAddress, indicator: FungibleResourceIndicator)
	case nonFungible(resourceAddress: ResourceAddress, indicator: NonFungibleResourceIndicator)
	public var resourceAddress: ResourceAddress {
		panic()
	}
}

// MARK: - FungibleResourceIndicator
public enum FungibleResourceIndicator: DummySargon {
	case guaranteed(amount: PredictedDecimal)
	case predicted(PredictedDecimal)
}

// MARK: - PredictedDecimal
public struct PredictedDecimal: DummySargon {
	public let value: RETDecimal
	public let instructionIndex: UInt64
}

public func + (lhs: PredictedDecimal, rhs: PredictedDecimal) -> PredictedDecimal {
	panic()
}

// MARK: - NonFungibleResourceIndicator
public enum NonFungibleResourceIndicator: DummySargon {
	case byAll(
		predictedAmount: PredictedDecimal,
		predictedIds: [NonFungibleLocalId]
	)
	case byAmount(
		amount: PredictedDecimal,
		predictedIds: [NonFungibleLocalId]
	)
	case byIds(ids: [NonFungibleLocalId])
//	public var ids: [NonFungibleLocalId] {
//		panic()
//	}
}

// MARK: - ReservedInstruction
public enum ReservedInstruction: DummySargon {}

// MARK: - DummySargonPublicKey
public enum DummySargonPublicKey: DummySargon {}

// MARK: - MetadataValue
public enum MetadataValue: DummySargon {}

// MARK: - EnginePublicKeyHash
public struct EnginePublicKeyHash: DeprecatedDummySargon {
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
	public var accountsDepositedInto: [EngineToolkitAddress] {
		panic()
	}

	public var accountsWithdrawnFrom: [EngineToolkitAddress] {
		panic()
	}

	public var accountsRequiringAuth: [EngineToolkitAddress] {
		panic()
	}

	public var identitiesRequiringAuth: [EngineToolkitAddress] {
		panic()
	}
}

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

	public func asSpecific() throws -> EngineToolkitAddress {
		panic()
	}

	public var asGeneral: EngineToolkitAddress {
		panic()
	}

	public func intoManifestBuilderAddress() -> Self {
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
		resourceAddress: ResourceAddress,
		nonFungibleLocalId: NonFungibleLocalId
	) -> Self {
		panic()
	}

	public func asStr() -> String {
		panic()
	}

	public func resourceAddress() -> ResourceAddress {
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

// MARK: - EnginePublicKey
public enum EnginePublicKey: DummySargon {
	case secp256k1(value: Data)
	case ed25519(value: Data)
	public var bytes: Data {
		panic()
	}
}

// MARK: - EngineSignatureWithPublicKey
public enum EngineSignatureWithPublicKey: DummySargon {
	public init(from: Any) {
		panic()
	}
}

// MARK: - EngineSignature
public enum EngineSignature: DummySargon {
	case secp256k1(value: Data)
	case ed25519(value: Data)
	public var bytes: Data {
		panic()
	}

	public var publicKey: EnginePublicKey? {
		panic()
	}

	public var signature: Data {
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

	public func intentSignatures() -> [EngineSignature] {
		panic()
	}

	public func signedIntentHash() -> TransactionHash {
		panic()
	}
}

// MARK: - TransactionIntent
public struct TransactionIntent: DummySargon {
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

	public func notarySignature() -> EngineSignature {
		panic()
	}
}

// MARK: - TransactionManifest
public struct TransactionManifest: DummySargon {
	public func extractAddresses() -> [EntityType: [EngineToolkitAddress]] {
		panic()
	}

	public func instructions() -> Instructions {
		panic()
	}

	public init(instructions: Instructions, blobs: [Data]) throws {
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
	case validatorClaim(Set<ValidatorAddress>, Bool)
	case validatorStake(validatorAddresses: [EngineToolkitAddress], validatorStakes: [TrackedValidatorStake])
	case validatorUnstake(validatorAddresses: [EngineToolkitAddress], validatorUnstakes: [TrackedValidatorUnstake], claimsNonFungibleData: [UnstakeDataEntry])
	case accountDepositSettingsUpdate(
		resourcePreferencesUpdates: [String: [String: ResourcePreferenceUpdate]],
		depositModeUpdates: [String: AccountDefaultDepositRule],
		authorizedDepositorsAdded:
		[String: [ResourceOrNonFungible]],
		authorizedDepositorsRemoved:
		[String: [ResourceOrNonFungible]]
	)

	case poolContribution(poolAddresses: [EngineToolkitAddress], poolContributions: [TrackedPoolContribution])
	case poolRedemption(poolAddresses: [EngineToolkitAddress], poolContributions: [TrackedPoolRedemption])
}

// MARK: - ExecutionSummary
public struct ExecutionSummary: DummySargon {
	public struct NewEntities: DummySargon {
		public var metadata: [String: [String: MetadataValue?]] {
			panic()
		}
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

	public var presentedProofs: [ResourceAddress] {
		panic()
	}

	public var encounteredEntities: [EngineToolkitAddress] {
		panic()
	}

	public var feeLocks: FeeLocks { panic() }
	public enum FeeLocks: DummySargon {
		public var lock: RETDecimal { panic() }
		public var contingentLock: RETDecimal { panic() }
	}

	public var feeSummary: FeeSummary { panic() }
	public enum FeeSummary: DummySargon {
		public var executionCost: RETDecimal { panic() }
		public var finalizationCost: RETDecimal { panic() }
		public var storageExpansionCost: RETDecimal { panic() }
		public var royaltyCost: RETDecimal { panic() }
	}
}

// MARK: - ResourceOrNonFungible
public enum ResourceOrNonFungible: DummySargon {
	case resource(ResourceAddress)
	case nonFungible(NonFungibleGlobalId)
}

// MARK: - KnownAddresses
public struct KnownAddresses: DummySargon {
	public struct ResourceAddresses: DummySargon {
		public var xrd: ResourceAddress {
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
	public static func assertWorktopContains(resourceAddress: Any, amount: Any) throws -> Self {
		panic()
	}
}

// MARK: - Instructions
public struct Instructions: DummySargon {
	public func asStr() -> String {
		panic()
	}

	public static func fromString(string: Any, networkId: UInt8) -> Self {
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

	public static func make(body: () async throws -> Void) -> ManifestBuilder {
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
	) throws -> TransactionManifest {
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

	public static func accountTryDepositOrAbort(_ args: Any?...) throws -> ManifestBuilder.InstructionsChain.Instruction {
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
public enum BuildInformation: DummySargon {
	public var version: String {
		panic()
	}
}

// MARK: Global Functions
public func buildInformation() -> BuildInformation {
	panic()
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
