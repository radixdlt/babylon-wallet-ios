import Bite
import Common
import ComposableArchitecture
import CryptoKit
import EngineToolkit
import Foundation
import enum SLIP10.PrivateKey
import enum SLIP10.PublicKey

// FIXME: move to SLIP10
public extension PrivateKey {
	var rawRepresentation: Data {
		switch self {
		case let .secp256k1(privateKey):
			return privateKey.rawRepresentation
		case let .curve25519(privateKey):
			return privateKey.rawRepresentation
		}
	}

	var hex: String {
		rawRepresentation.hex
	}
}

// FIXME: move to EngineToolkit
public extension Engine.Signature {
	var bytes: [UInt8] {
		switch self {
		case let .ecdsaSecp256k1(signature):
			return signature.bytes
		case let .eddsaEd25519(signature):
			return signature.bytes
		}
	}

	var hex: String {
		bytes.hex
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
			}
		)
	}
}
