import Cryptography
import EngineToolkitModels
import Prelude

public extension TransactionManifest {
	func header(_ header: TransactionHeader) -> TransactionIntent {
		.init(header: header, manifest: self)
	}
}

public extension TransactionIntent {
	func blobs(_ blobs: [[UInt8]]) -> Self {
		.init(header: header, manifest: .init(instructions: manifest.instructions, blobs: blobs))
	}
}

// MARK: - NotarizedNonNotarySignedButIntentSignedTransctionContext
public struct NotarizedNonNotarySignedButIntentSignedTransctionContext: Hashable {
	public internal(set) var transactionIntent: TransactionIntent
	public internal(set) var transactionIntentHash: Data
	public internal(set) var compileTransactionIntentResponse: CompileTransactionIntentResponse
	public internal(set) var signedTransactionIntent: SignedTransactionIntent

	fileprivate func with(
		compileSignedTransactionIntentResponse: CompileSignedTransactionIntentResponse,
		notarizedTransaction: NotarizedTransaction,
		notarizedTransactionHash: Data
	) -> NotarizedSignedTransctionContext {
		.init(
			transactionIntent: transactionIntent,
			transactionIntentHash: transactionIntentHash,
			compileTransactionIntentResponse: compileTransactionIntentResponse,
			signedTransactionIntent: signedTransactionIntent,
			compileSignedTransactionIntentResponse: compileSignedTransactionIntentResponse,
			notarizedTransactionHash: notarizedTransactionHash,
			notarizedTransaction: notarizedTransaction
		)
	}
}

// MARK: - NotarizedSignedTransctionContext
public struct NotarizedSignedTransctionContext: Hashable {
	public internal(set) var transactionIntent: TransactionIntent
	public internal(set) var transactionIntentHash: Data
	public internal(set) var compileTransactionIntentResponse: CompileTransactionIntentResponse
	public internal(set) var signedTransactionIntent: SignedTransactionIntent
	public internal(set) var compileSignedTransactionIntentResponse: CompileSignedTransactionIntentResponse
	public internal(set) var notarizedTransactionHash: Data
	public internal(set) var notarizedTransaction: NotarizedTransaction
}

public extension TransactionIntent {
	func sign(with privateKey: Curve25519.Signing.PrivateKey) throws -> NotarizedNonNotarySignedButIntentSignedTransctionContext {
		try sign(with: Engine.PrivateKey.curve25519(privateKey))
	}

	func sign(with privateKey: K1.PrivateKey) throws -> NotarizedNonNotarySignedButIntentSignedTransctionContext {
		try sign(with: Engine.PrivateKey.secp256k1(privateKey))
	}

	func sign(with privateKey: SLIP10.PrivateKey) throws -> NotarizedNonNotarySignedButIntentSignedTransctionContext {
		try sign(with: privateKey.intoEngine())
	}

	func sign(with privateKey: Engine.PrivateKey) throws -> NotarizedNonNotarySignedButIntentSignedTransctionContext {
		try sign(withMany: [privateKey])
	}

	func sign(withMany privateKeys: [Engine.PrivateKey]) throws -> NotarizedNonNotarySignedButIntentSignedTransctionContext {
		let compiledTransactionIntentResponse = try EngineToolkit()
			.compileTransactionIntentRequest(
				request: self
			).get()
		let compiledTransactionIntent = compiledTransactionIntentResponse.compiledIntent

		let intentSignaturesWithHash = try privateKeys.map {
			try $0.signReturningHashOfMessage(data: compiledTransactionIntent)
		}
		let transactionIntentHash = intentSignaturesWithHash.first?.hashOfMessage ?? Data(SHA256.twice(data: compiledTransactionIntent))
		assert(intentSignaturesWithHash.map(\.hashOfMessage).allSatisfy { $0 == transactionIntentHash })

		let signedTransactionIntent = SignedTransactionIntent(
			intent: self,
			intentSignatures: intentSignaturesWithHash.map(\.signatureWithPublicKey)
		)

		return NotarizedNonNotarySignedButIntentSignedTransctionContext(
			transactionIntent: self,
			transactionIntentHash: transactionIntentHash,
			compileTransactionIntentResponse: compiledTransactionIntentResponse,
			signedTransactionIntent: signedTransactionIntent
		)
	}
}

public extension NotarizedNonNotarySignedButIntentSignedTransctionContext {
	func sign(with privateKey: Curve25519.Signing.PrivateKey) throws -> NotarizedNonNotarySignedButIntentSignedTransctionContext {
		try sign(with: Engine.PrivateKey.curve25519(privateKey))
	}

	func sign(with privateKey: K1.PrivateKey) throws -> NotarizedNonNotarySignedButIntentSignedTransctionContext {
		try sign(with: Engine.PrivateKey.secp256k1(privateKey))
	}

	func sign(with privateKey: SLIP10.PrivateKey) throws -> NotarizedNonNotarySignedButIntentSignedTransctionContext {
		try sign(with: privateKey.intoEngine())
	}

	func sign(with privateKey: Engine.PrivateKey) throws -> NotarizedNonNotarySignedButIntentSignedTransctionContext {
		let compiledSignedTransactionIntent = try EngineToolkit().compileSignedTransactionIntentRequest(
			request: self.signedTransactionIntent
		).get().compiledIntent

		let (signature, _) = try privateKey.signReturningHashOfMessage(data: compiledSignedTransactionIntent)

		let signedTransactionIntent = SignedTransactionIntent(
			intent: transactionIntent,
			intentSignatures: self.signedTransactionIntent.intentSignatures + [signature]
		)
		var mutableSelf = self
		mutableSelf.signedTransactionIntent = signedTransactionIntent
		return mutableSelf
	}
}

public extension NotarizedNonNotarySignedButIntentSignedTransctionContext {
	func notarize(_ notaryPrivateKey: Curve25519.Signing.PrivateKey) throws -> NotarizedSignedTransctionContext {
		try notarize(Engine.PrivateKey.curve25519(notaryPrivateKey))
	}

	func notarize(_ notaryPrivateKey: K1.PrivateKey) throws -> NotarizedSignedTransctionContext {
		try notarize(Engine.PrivateKey.secp256k1(notaryPrivateKey))
	}

	func notarize(_ notaryPrivateKey: SLIP10.PrivateKey) throws -> NotarizedSignedTransctionContext {
		try notarize(notaryPrivateKey.intoEngine())
	}

	func notarize(_ notaryPrivateKey: Engine.PrivateKey) throws -> NotarizedSignedTransctionContext {
		let compileSignedTransactionIntentResponse = try EngineToolkit().compileSignedTransactionIntentRequest(
			request: signedTransactionIntent
		).get()

		let compiledSignedTransactionIntent = compileSignedTransactionIntentResponse.compiledIntent

		// Notarize the signed intent to create a notarized transaction
		let (notarySignature, notarizedTransactionHash) = try notaryPrivateKey.signReturningHashOfMessage(
			data: compiledSignedTransactionIntent
		)

		let notarizedTransaction = NotarizedTransaction(
			signedIntent: signedTransactionIntent,
			notarySignature: notarySignature.signature
		)

		return with(
			compileSignedTransactionIntentResponse: compileSignedTransactionIntentResponse,
			notarizedTransaction: notarizedTransaction,
			notarizedTransactionHash: notarizedTransactionHash
		)
	}
}

public extension TransactionIntent {
	func notarize(_ notaryPrivateKey: Curve25519.Signing.PrivateKey) throws -> NotarizedSignedTransctionContext {
		try notarize(Engine.PrivateKey.curve25519(notaryPrivateKey))
	}

	func notarize(_ notaryPrivateKey: K1.PrivateKey) throws -> NotarizedSignedTransctionContext {
		try notarize(Engine.PrivateKey.secp256k1(notaryPrivateKey))
	}

	func notarize(_ notaryPrivateKey: SLIP10.PrivateKey) throws -> NotarizedSignedTransctionContext {
		try notarize(notaryPrivateKey.intoEngine())
	}

	func notarize(_ notaryPrivateKey: Engine.PrivateKey) throws -> NotarizedSignedTransctionContext {
		try sign(withMany: []) // a bit hacky, but hey, it works!
			.notarize(notaryPrivateKey)
	}
}
