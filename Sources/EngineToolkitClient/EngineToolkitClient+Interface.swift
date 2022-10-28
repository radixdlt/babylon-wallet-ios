import Bite
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
	public init(signTransactionIntent: @escaping SignTransactionIntent) {
		self.signTransactionIntent = signTransactionIntent
	}
}

// MARK: - SignedCompiledNotarizedTX
public struct SignedCompiledNotarizedTX: Sendable, Hashable {
	public let compileTransactionIntentResponse: CompileTransactionIntentResponse
	public let intentHash: Data
	public let compileNotarizedTransactionIntentResponse: CompileNotarizedTransactionIntentResponse
}

// MARK: - EngineToolkitClient.SignTransactionIntent
public extension EngineToolkitClient {
	typealias SignTransactionIntent = @Sendable (SignTransactionIntentRequest) throws -> SignedCompiledNotarizedTX
}
