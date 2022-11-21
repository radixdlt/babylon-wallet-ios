import Common
import ComposableArchitecture
import CryptoKit
import EngineToolkit
import Foundation
import struct Profile.AccountAddress
import enum SLIP10.PrivateKey
import enum SLIP10.PublicKey

// MARK: - EngineToolkitClient
public struct EngineToolkitClient: DependencyKey {
	public var getTransactionVersion: GetTransactionVersion
	public var signTransactionIntent: SignTransactionIntent
	public var accountAddressesNeedingToSignTransaction: AccountAddressesNeedingToSignTransaction

	public init(
		getTransactionVersion: @escaping GetTransactionVersion,
		signTransactionIntent: @escaping SignTransactionIntent,
		accountAddressesNeedingToSignTransaction: @escaping AccountAddressesNeedingToSignTransaction
	) {
		self.getTransactionVersion = getTransactionVersion
		self.signTransactionIntent = signTransactionIntent
		self.accountAddressesNeedingToSignTransaction = accountAddressesNeedingToSignTransaction
	}
}

public extension EngineToolkitClient {
	typealias GetTransactionVersion = @Sendable () -> Version
	typealias SignTransactionIntent = @Sendable (SignTransactionIntentRequest) throws -> SignedCompiledNotarizedTX
	typealias AccountAddressesNeedingToSignTransaction = @Sendable (Version, TransactionManifest, NetworkID) throws -> Set<AccountAddress>
}

// MARK: - SignedCompiledNotarizedTX
public struct SignedCompiledNotarizedTX: Sendable, Hashable {
	public let compileTransactionIntentResponse: CompileTransactionIntentResponse
	public let intentHash: Data
	public let compileNotarizedTransactionIntentResponse: CompileNotarizedTransactionIntentResponse
}
