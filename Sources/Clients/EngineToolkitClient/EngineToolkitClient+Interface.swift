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

	public typealias AnalyzeManifest = @Sendable (AnalyzeManifestRequest) throws -> AnalyzeManifestResponse
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

extension AccountAddress {
	public init(componentAddress: ComponentAddress) throws {
		try self.init(address: componentAddress.address)
	}
}
