import Bite
import Common
import ComposableArchitecture
import CryptoKit
import EngineToolkit
import Foundation
import enum SLIP10.PrivateKey
import enum SLIP10.PublicKey

public extension Nonce {
	static func secureRandom() -> Self {
		let byteCount = RawValue.bitWidth / 8
		var data = Data(repeating: 0, count: byteCount)
		data.withUnsafeMutableBytes {
			assert($0.count == byteCount)
			$0.initializeWithRandomBytes(count: byteCount)
		}
		let rawValue = data.withUnsafeBytes { $0.load(as: RawValue.self) }
		return Self(rawValue: rawValue)
	}
}

public extension EngineToolkitClient {
	static func live(
		engineToolkit: EngineToolkit = .init()
	) -> Self {
		Self(
			signTransactionIntent: { request in

				let privateKey = request.privateKey
				let transactionIntent = request.transactionIntent

				let compiledTransactionIntent = try engineToolkit.compileTransactionIntentRequest(
					request: transactionIntent
				).get()

				let transactionIntentWithSignatures = SignedTransactionIntent(
					intent: transactionIntent,
					intentSignatures: []
				)

				let forNotarySignerToSign = try engineToolkit
					.compileSignedTransactionIntentRequest(request: transactionIntentWithSignatures)
					.get()

				let (signedCompiledSignedTXIntent, _) = try privateKey.signReturningHashOfMessage(
					data: forNotarySignerToSign.compiledSignedIntent
				)

				let notarizedTX = try NotarizedTransaction(
					signedIntent: transactionIntentWithSignatures,
					notarySignature: signedCompiledSignedTXIntent.intoEngine().signature
				)

				let notarizedTransactionIntent = try engineToolkit
					.compileNotarizedTransactionIntentRequest(request: notarizedTX)
					.get()

				let intentHash = Data(
					SHA256.twice(data: Data(compiledTransactionIntent.compiledIntent))
				)

				return .init(
					compileTransactionIntentResponse: compiledTransactionIntent,
					intentHash: intentHash,
					compileNotarizedTransactionIntentResponse: notarizedTransactionIntent
				)
			}
		)
	}
}
