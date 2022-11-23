import Common
import ComposableArchitecture
import CryptoKit
import EngineToolkit
import Foundation
import struct Profile.AccountAddress
import enum SLIP10.PrivateKey
import enum SLIP10.PublicKey

// MARK: - EngineToolkitClient
public struct EngineToolkitClient: Sendable, DependencyKey {
	public var getTransactionVersion: GetTransactionVersion
	public var generateTXNonce: GenerateTXNonce

	public var compileTransactionIntent: CompileTransactionIntent
	public var compileSignedTransactionIntent: CompileSignedTransactionIntent
	public var compileNotarizedTransactionIntent: CompileNotarizedTransactionIntent

	public var generateTXID: GenerateTXID
	public var accountAddressesNeedingToSignTransaction: AccountAddressesNeedingToSignTransaction
}

public extension EngineToolkitClient {
	typealias GetTransactionVersion = @Sendable () -> Version

	typealias GenerateTXNonce = @Sendable () -> Nonce

	typealias AccountAddressesNeedingToSignTransaction = @Sendable (AccountAddressesNeedingToSignTransactionRequest) throws -> Set<AccountAddress>

	typealias CompileTransactionIntent = @Sendable (TransactionIntent) throws -> CompileTransactionIntentResponse

	typealias CompileSignedTransactionIntent = @Sendable (SignedTransactionIntent) throws -> CompileSignedTransactionIntentResponse

	typealias CompileNotarizedTransactionIntent = @Sendable (NotarizedTransaction) throws -> CompileNotarizedTransactionIntentResponse

	typealias GenerateTXID = @Sendable (TransactionIntent) throws -> TXID
}

// MARK: - AccountAddressesNeedingToSignTransactionRequest
public struct AccountAddressesNeedingToSignTransactionRequest: Sendable, Hashable {
	public let version: Version
	public let manifest: TransactionManifest
	public let networkID: NetworkID
	public init(version: Version, manifest: TransactionManifest, networkID: NetworkID) {
		self.version = version
		self.manifest = manifest
		self.networkID = networkID
	}
}
