import Common
import CryptoKit
import Dependencies
import EngineToolkit
import Foundation
import enum SLIP10.PrivateKey
import enum SLIP10.PublicKey

public extension EngineToolkitClient {
	static let liveValue: Self = {
		let engineToolkit = EngineToolkit()

		return Self(
			signTransactionIntent: { request in

				let privateKey = request.privateKey

				let transactionIntent = request.transactionIntent

				do {
					let compiledTransactionIntent = try engineToolkit.compileTransactionIntentRequest(
						request: transactionIntent
					).get()

					let transactionIntentWithSignatures = SignedTransactionIntent(
						intent: transactionIntent,
						intentSignatures: []
					)

					let compiledSignedIntentResponse = try engineToolkit
						.compileSignedTransactionIntentRequest(request: transactionIntentWithSignatures)
						.get()

					let (signedCompiledSignedTXIntent, _) = try privateKey.signReturningHashOfMessage(
						data: compiledSignedIntentResponse.compiledSignedIntent
					)

					let notarySignature = try signedCompiledSignedTXIntent.intoEngine().signature

					let notarizedTX = NotarizedTransaction(
						signedIntent: transactionIntentWithSignatures,
						notarySignature: notarySignature
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
				} catch {
					print("⚠️ Failed to sign, error: \(error)")
					print("⚠️ Failed to sign, error: \(error)")
					throw error
				}
			}
		)
	}()
}
