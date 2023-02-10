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

	public var generateTXID: GenerateTXID
	public var accountAddressesNeedingToSignTransaction: AccountAddressesNeedingToSignTransaction
	public var accountAddressesSuitableToPayTransactionFee: AccountAddressesSuitableToPayTransactionFee

	public var knownEntityAddresses: KnownEntityAddresses
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

public extension EngineToolkitClient {
	typealias GetTransactionVersion = @Sendable () -> TXVersion

	typealias GenerateTXNonce = @Sendable () -> Nonce

	typealias ConvertManifestInstructionsToJSONIfItWasString = @Sendable (ConvertManifestInstructionsToJSONIfItWasStringRequest) throws -> JSONInstructionsTransactionManifest

	typealias AccountAddressesNeedingToSignTransaction = @Sendable (AccountAddressesInvolvedInTransactionRequest) throws -> Set<AccountAddress>
	typealias AccountAddressesSuitableToPayTransactionFee = @Sendable (AccountAddressesInvolvedInTransactionRequest) throws -> Set<AccountAddress>

	typealias CompileTransactionIntent = @Sendable (TransactionIntent) throws -> CompileTransactionIntentResponse

	typealias CompileSignedTransactionIntent = @Sendable (SignedTransactionIntent) throws -> CompileSignedTransactionIntentResponse

	typealias CompileNotarizedTransactionIntent = @Sendable (NotarizedTransaction) throws -> CompileNotarizedTransactionIntentResponse

	typealias GenerateTXID = @Sendable (TransactionIntent) throws -> TXID

	typealias KnownEntityAddresses = @Sendable (NetworkID) throws -> KnownEntityAddressesResponse
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
