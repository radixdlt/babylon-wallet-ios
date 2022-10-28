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
				#if DEBUG
				print(String(repeating: "☣️", count: 50))
				print("CRITICAL WARNING! PRINTING PRIVATE KEYS IN DEBUG MODE")
				print("private key:")
				print(privateKey.hex)
				print(String(repeating: "☣️", count: 50))
				#endif
				let transactionIntent = request.transactionIntent

				print("\n🔮⚙️🧰 Manifest:", transactionIntent.manifest)

				let compiledTransactionIntent = try engineToolkit.compileTransactionIntentRequest(
					request: transactionIntent
				).get()

				print("🔮⚙️🧰 Compiled Transaction Intent:\n\(compiledTransactionIntent.compiledIntent.hex)\n\n")

				let transactionIntentWithSignatures = SignedTransactionIntent(
					intent: transactionIntent,
					intentSignatures: []
				)

				let compiledSignedIntentResponse = try engineToolkit
					.compileSignedTransactionIntentRequest(request: transactionIntentWithSignatures)
					.get()

				print("🔮⚙️🧰 Compiled Signed Intent:\n\(compiledSignedIntentResponse.compiledSignedIntent.hex)\n\n")

				let (signedCompiledSignedTXIntent, hashOfSignedIntent) = try privateKey.signReturningHashOfMessage(
					data: compiledSignedIntentResponse.compiledSignedIntent
				)

				let notarySignature = try signedCompiledSignedTXIntent.intoEngine().signature
				print("🔮⚙️🧰 Compiled signed intent signature:\n\(notarySignature.hex)\n\n")
				print("🔮⚙️🧰 Compiled signed intent hash:\n\(hashOfSignedIntent.hex)\n\n")

				let notarizedTX = NotarizedTransaction(
					signedIntent: transactionIntentWithSignatures,
					notarySignature: notarySignature
				)

				let notarizedTransactionIntent = try engineToolkit
					.compileNotarizedTransactionIntentRequest(request: notarizedTX)
					.get()

				print("🔮⚙️🧰 Compiled notarized transaction intent:\n\(notarizedTransactionIntent.compiledNotarizedIntent.hex)\n\n")

				let intentHash = Data(
					SHA256.twice(data: Data(compiledTransactionIntent.compiledIntent))
				)

				print("🔮⚙️🧰 Compiled Intent hash:\n\(intentHash.hex)\n\n")

				return .init(
					compileTransactionIntentResponse: compiledTransactionIntent,
					intentHash: intentHash,
					compileNotarizedTransactionIntentResponse: notarizedTransactionIntent
				)
			}
		)
	}
}
