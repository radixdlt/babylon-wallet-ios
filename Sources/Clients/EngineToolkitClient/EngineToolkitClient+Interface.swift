import Common
import ComposableArchitecture
import CryptoKit
import EngineToolkit
import Foundation
import enum SLIP10.PrivateKey
import enum SLIP10.PublicKey

// MARK: - EngineToolkitClient
public struct EngineToolkitClient: DependencyKey {
	public var signTransactionIntent: SignTransactionIntent
	public var accountAddressesNeedingToSignTransaction: AccountAddressesNeedingToSignTransaction

	public init(
		signTransactionIntent: @escaping SignTransactionIntent,
		accountAddressesNeedingToSignTransaction: @escaping AccountAddressesNeedingToSignTransaction
	) {
		self.signTransactionIntent = signTransactionIntent
		self.accountAddressesNeedingToSignTransaction = accountAddressesNeedingToSignTransaction
	}
}

// MARK: - EngineToolkitClient.SignTransactionIntent
public extension EngineToolkitClient {
	typealias SignTransactionIntent = @Sendable (SignTransactionIntentRequest) throws -> SignedCompiledNotarizedTX
	typealias AccountAddressesNeedingToSignTransaction = @Sendable (Version, TransactionManifest, NetworkID) throws -> [ComponentAddress]
}

// MARK: - SignedCompiledNotarizedTX
public struct SignedCompiledNotarizedTX: Sendable, Hashable {
	public let compileTransactionIntentResponse: CompileTransactionIntentResponse
	public let intentHash: Data
	public let compileNotarizedTransactionIntentResponse: CompileNotarizedTransactionIntentResponse
}
