import ClientPrelude
import Cryptography
import EngineToolkit

// MARK: - EngineToolkitClient
public struct EngineToolkitClient: Sendable, DependencyKey {
	public var getTransactionVersion: GetTransactionVersion
	public var generateTXNonce: GenerateTXNonce

	public var convertManifestInstructionsToJSONIfItWasString: ConvertManifestInstructionsToJSONIfItWasString

	public var compileTransactionIntent: CompileTransactionIntent
	public var compileSignedTransactionIntent: CompileSignedTransactionIntent
	public var compileNotarizedTransactionIntent: CompileNotarizedTransactionIntent
	public var decompileTransactionIntent: DecompileTransactionIntent
	public var decompileNotarizedTransactionIntent: DecompileNotarizedTransactionIntent

	public var deriveOlympiaAdressFromPublicKey: DeriveOlympiaAdressFromPublicKey

	public var generateTXID: GenerateTXID

	public var knownEntityAddresses: KnownEntityAddresses

	public var analyzeManifest: AnalyzeManifest
	public var analyzeManifestWithPreviewContext: AnalyzeManifestWithPreviewContext

	public var decodeAddress: DecodeAddressRequest
}

// MARK: - JSONInstructionsTransactionManifest
public struct JSONInstructionsTransactionManifest: Sendable, Hashable {
	public let instructions: [Instruction]
	public let convertedManifestThatContainsThem: TransactionManifest
	public init(instructions: [Instruction], convertedManifestThatContainsThem: TransactionManifest) {
		self.instructions = instructions
		self.convertedManifestThatContainsThem = convertedManifestThatContainsThem
	}
}

// MARK: - ConvertManifestInstructionsToJSONIfItWasStringRequest
public struct ConvertManifestInstructionsToJSONIfItWasStringRequest: Sendable, Hashable {
	public let version: TXVersion
	public let networkID: NetworkID
	public let manifest: TransactionManifest
	public init(version: TXVersion, networkID: NetworkID, manifest: TransactionManifest) {
		self.version = version
		self.networkID = networkID
		self.manifest = manifest
	}
}

extension EngineToolkitClient {
	public typealias GetTransactionVersion = @Sendable () -> TXVersion

	public typealias GenerateTXNonce = @Sendable () -> Nonce

	public typealias ConvertManifestInstructionsToJSONIfItWasString = @Sendable (ConvertManifestInstructionsToJSONIfItWasStringRequest) throws -> JSONInstructionsTransactionManifest

	public typealias CompileTransactionIntent = @Sendable (TransactionIntent) throws -> CompileTransactionIntentResponse

	public typealias CompileSignedTransactionIntent = @Sendable (SignedTransactionIntent) throws -> CompileSignedTransactionIntentResponse

	public typealias CompileNotarizedTransactionIntent = @Sendable (NotarizedTransaction) throws -> CompileNotarizedTransactionIntentResponse

	public typealias DeriveOlympiaAdressFromPublicKey = @Sendable (K1.PublicKey) throws -> String

	public typealias GenerateTXID = @Sendable (TransactionIntent) throws -> TXID

	public typealias KnownEntityAddresses = @Sendable (NetworkID) throws -> KnownEntityAddressesResponse

	public typealias AnalyzeManifest = @Sendable (AnalyzeManifestRequest) throws -> AnalyzedManifest
	public typealias AnalyzeManifestWithPreviewContext = @Sendable (AnalyzeManifestWithPreviewContextRequest) throws -> AnalyzeManifestWithPreviewContextResponse

	public typealias DecodeAddressRequest = @Sendable (String) throws -> DecodeAddressResponse

	public typealias DecompileTransactionIntent = @Sendable (DecompileTransactionIntentRequest) throws -> DecompileTransactionIntentResponse
	public typealias DecompileNotarizedTransactionIntent = @Sendable (DecompileNotarizedTransactionIntentRequest) throws -> DecompileNotarizedTransactionIntentResponse
}

// MARK: - AnalyzeManifestRequest
public struct AnalyzeManifestRequest: Sendable, Hashable {
	public let manifest: TransactionManifest
	public let networkID: NetworkID

	public init(
		manifest: TransactionManifest,
		networkID: NetworkID
	) {
		self.manifest = manifest
		self.networkID = networkID
	}
}

// MARK: - TransactionManifest + CustomDumpStringConvertible
extension TransactionManifest: CustomDumpStringConvertible {
	public var customDumpDescription: String {
		description
	}
}

import Profile

// MARK: - AnalyzedManifest
public struct AnalyzedManifest: Sendable, Hashable {
	public let packageAddresses: OrderedSet<PackageAddress>
	public let resourceAddresses: OrderedSet<ResourceAddress>
	public let componentAddresses: OrderedSet<ComponentAddress>

	/// A set of all of the account component addresses seen in the manifest.
	public let accountAddresses: OrderedSet<AccountAddress>

	/// A set of all of the account component addresses in the manifest which had methods invoked on them that would typically require auth (or a signature) to be called successfully.
	public let accountsRequiringAuth: OrderedSet<AccountAddress>

	/// A set of all of the account component addresses in the manifest which were deposited into. This is a subset of the addresses seen in `accountAddresses`.
	public let accountsWithdrawnFrom: OrderedSet<AccountAddress>

	/// A set of all of the account component addresses in the manifest which were withdrawn from. This is a subset of the addresses seen in `accountAddresses`
	public let accountsDepositedInto: OrderedSet<AccountAddress>

	public init(
		packageAddresses: OrderedSet<PackageAddress>,
		resourceAddresses: OrderedSet<ResourceAddress>,
		componentAddresses: OrderedSet<ComponentAddress>,
		accountAddresses: OrderedSet<AccountAddress>,
		accountsRequiringAuth: OrderedSet<AccountAddress>,
		accountsDepositedInto: OrderedSet<AccountAddress>,
		accountsWithdrawnFrom: OrderedSet<AccountAddress>
	) {
		self.packageAddresses = packageAddresses
		self.resourceAddresses = resourceAddresses
		self.componentAddresses = componentAddresses
		self.accountAddresses = accountAddresses
		self.accountsRequiringAuth = accountsRequiringAuth
		self.accountsDepositedInto = accountsDepositedInto
		self.accountsWithdrawnFrom = accountsWithdrawnFrom
	}

	public init(
		response: AnalyzeManifestResponse
	) throws {
		try self.init(
			packageAddresses: .init(validating: response.packageAddresses),
			resourceAddresses: .init(validating: response.resourceAddresses),
			componentAddresses: .init(validating: response.componentAddresses),
			accountAddresses: .init(validating: response.accountAddresses.map { try AccountAddress(componentAddress: $0) }),
			accountsRequiringAuth: .init(validating: response.accountsRequiringAuth.map { try AccountAddress(componentAddress: $0) }),
			accountsDepositedInto: .init(validating: response.accountsDepositedInto.map { try AccountAddress(componentAddress: $0) }),
			accountsWithdrawnFrom: .init(validating: response.accountsWithdrawnFrom.map { try AccountAddress(componentAddress: $0) })
		)
	}
}

extension AccountAddress {
	public init(componentAddress: ComponentAddress) throws {
		try self.init(address: componentAddress.address)
	}
}
