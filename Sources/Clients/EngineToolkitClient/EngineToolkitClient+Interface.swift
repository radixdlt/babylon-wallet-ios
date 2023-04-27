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
	public var decompileTransactionIntentRequest: DecompileTransactionIntentRequest

	public var deriveOlympiaAdressFromPublicKey: DeriveOlympiaAdressFromPublicKey

	public var generateTXID: GenerateTXID
	public var accountAddressesNeedingToSignTransaction: AccountAddressesNeedingToSignTransaction
	public var accountAddressesSuitableToPayTransactionFee: AccountAddressesSuitableToPayTransactionFee

	public var knownEntityAddresses: KnownEntityAddresses

	public var generateTransactionReview: GenerateTransactionReview
	public var decodeAddress: DecodeAddressRequest
}

// MARK: - JSONInstructionsTransactionManifest
public struct JSONInstructionsTransactionManifest: Sendable, Hashable {
	public let instructions: [Instruction]
	public let convertedManifestThatContainsThem: TransactionManifest
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

	public typealias AccountAddressesNeedingToSignTransaction = @Sendable (AccountAddressesInvolvedInTransactionRequest) throws -> Set<AccountAddress>
	public typealias AccountAddressesSuitableToPayTransactionFee = @Sendable (AccountAddressesInvolvedInTransactionRequest) throws -> Set<AccountAddress>

	public typealias CompileTransactionIntent = @Sendable (TransactionIntent) throws -> CompileTransactionIntentResponse

	public typealias CompileSignedTransactionIntent = @Sendable (SignedTransactionIntent) throws -> CompileSignedTransactionIntentResponse

	public typealias CompileNotarizedTransactionIntent = @Sendable (NotarizedTransaction) throws -> CompileNotarizedTransactionIntentResponse

	public typealias DeriveOlympiaAdressFromPublicKey = @Sendable (K1.PublicKey) throws -> String

	public typealias GenerateTXID = @Sendable (TransactionIntent) throws -> TXID

	public typealias KnownEntityAddresses = @Sendable (NetworkID) throws -> KnownEntityAddressesResponse

	public typealias GenerateTransactionReview = @Sendable (AnalyzeManifestWithPreviewContextRequest) throws -> AnalyzeManifestWithPreviewContextResponse

	public typealias DecodeAddressRequest = @Sendable (String) throws -> DecodeAddressResponse

	public typealias DecompileTransactionIntentRequest = @Sendable (EngineToolkitModels.DecompileTransactionIntentRequest) throws -> DecompileTransactionIntentResponse
}

// MARK: - AccountAddressesInvolvedInTransactionRequest
public struct AccountAddressesInvolvedInTransactionRequest: Sendable, Hashable {
	public let version: TXVersion
	public let manifest: TransactionManifest
	public let networkID: NetworkID

	public init(
		version: TXVersion,
		manifest: TransactionManifest,
		networkID: NetworkID
	) {
		self.version = version
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
