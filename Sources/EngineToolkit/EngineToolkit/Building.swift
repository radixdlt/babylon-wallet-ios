import Cryptography
import EngineToolkitModels
import Prelude

extension TransactionManifest {
	public func header(_ header: TransactionHeader) -> TransactionIntent {
		.init(header: header, manifest: self)
	}
}

extension TransactionIntent {
	public func blobs(_ blobs: [[UInt8]]) -> Self {
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

extension TransactionIntent {
	public func sign(with privateKey: Curve25519.Signing.PrivateKey) throws -> NotarizedNonNotarySignedButIntentSignedTransctionContext {
		try sign(with: Engine.PrivateKey.curve25519(privateKey))
	}

	public func sign(with privateKey: K1.PrivateKey) throws -> NotarizedNonNotarySignedButIntentSignedTransctionContext {
		try sign(with: Engine.PrivateKey.secp256k1(privateKey))
	}

	public func sign(with privateKey: SLIP10.PrivateKey) throws -> NotarizedNonNotarySignedButIntentSignedTransctionContext {
		try sign(with: privateKey.intoEngine())
	}

	public func sign(with privateKey: Engine.PrivateKey) throws -> NotarizedNonNotarySignedButIntentSignedTransctionContext {
		try sign(withMany: [privateKey])
	}

	public func sign(withMany privateKeys: [Engine.PrivateKey]) throws -> NotarizedNonNotarySignedButIntentSignedTransctionContext {
		let compiledTransactionIntentResponse = try EngineToolkit()
			.compileTransactionIntentRequest(
				request: self
			).get()
		let compiledTransactionIntent = compiledTransactionIntentResponse.compiledIntent

		let transactionIntentHash = try blake2b(data: compiledTransactionIntent)
		let intentSignatures = try privateKeys.map {
			try $0.sign(hashOfMessage: transactionIntentHash)
		}

		let signedTransactionIntent = SignedTransactionIntent(
			intent: self,
			intentSignatures: intentSignatures
		)

		return NotarizedNonNotarySignedButIntentSignedTransctionContext(
			transactionIntent: self,
			transactionIntentHash: transactionIntentHash,
			compileTransactionIntentResponse: compiledTransactionIntentResponse,
			signedTransactionIntent: signedTransactionIntent
		)
	}
}

extension NotarizedNonNotarySignedButIntentSignedTransctionContext {
	public func sign(with privateKey: Curve25519.Signing.PrivateKey) throws -> NotarizedNonNotarySignedButIntentSignedTransctionContext {
		try sign(with: Engine.PrivateKey.curve25519(privateKey))
	}

	public func sign(with privateKey: K1.PrivateKey) throws -> NotarizedNonNotarySignedButIntentSignedTransctionContext {
		try sign(with: Engine.PrivateKey.secp256k1(privateKey))
	}

	public func sign(with privateKey: SLIP10.PrivateKey) throws -> NotarizedNonNotarySignedButIntentSignedTransctionContext {
		try sign(with: privateKey.intoEngine())
	}

	public func sign(with privateKey: Engine.PrivateKey) throws -> NotarizedNonNotarySignedButIntentSignedTransctionContext {
		let compiledSignedTransactionIntent = try EngineToolkit().compileSignedTransactionIntentRequest(
			request: self.signedTransactionIntent
		).get().compiledIntent

		let hashOfTransactionIntent = try blake2b(data: compiledSignedTransactionIntent)
		let signature = try privateKey.sign(hashOfMessage: hashOfTransactionIntent)

		let signedTransactionIntent = SignedTransactionIntent(
			intent: transactionIntent,
			intentSignatures: self.signedTransactionIntent.intentSignatures + [signature]
		)
		var mutableSelf = self
		mutableSelf.signedTransactionIntent = signedTransactionIntent
		return mutableSelf
	}
}

extension NotarizedNonNotarySignedButIntentSignedTransctionContext {
	public func notarize(_ notaryPrivateKey: Curve25519.Signing.PrivateKey) throws -> NotarizedSignedTransctionContext {
		try notarize(Engine.PrivateKey.curve25519(notaryPrivateKey))
	}

	public func notarize(_ notaryPrivateKey: K1.PrivateKey) throws -> NotarizedSignedTransctionContext {
		try notarize(Engine.PrivateKey.secp256k1(notaryPrivateKey))
	}

	public func notarize(_ notaryPrivateKey: SLIP10.PrivateKey) throws -> NotarizedSignedTransctionContext {
		try notarize(notaryPrivateKey.intoEngine())
	}

	public func notarize(_ notaryPrivateKey: Engine.PrivateKey) throws -> NotarizedSignedTransctionContext {
		let compileSignedTransactionIntentResponse = try EngineToolkit().compileSignedTransactionIntentRequest(
			request: signedTransactionIntent
		).get()

		let compiledSignedTransactionIntent = compileSignedTransactionIntentResponse.compiledIntent

		let hashOfTransactionIntent = try blake2b(data: compiledSignedTransactionIntent)

		// Notarize the signed intent to create a notarized transaction
		let notarySignature = try notaryPrivateKey
			.sign(hashOfMessage: hashOfTransactionIntent)

		let notarizedTransaction = NotarizedTransaction(
			signedIntent: signedTransactionIntent,
			notarySignature: notarySignature.signature
		)

		return with(
			compileSignedTransactionIntentResponse: compileSignedTransactionIntentResponse,
			notarizedTransaction: notarizedTransaction,
			notarizedTransactionHash: hashOfTransactionIntent
		)
	}
}

extension TransactionIntent {
	public func notarize(_ notaryPrivateKey: Curve25519.Signing.PrivateKey) throws -> NotarizedSignedTransctionContext {
		try notarize(Engine.PrivateKey.curve25519(notaryPrivateKey))
	}

	public func notarize(_ notaryPrivateKey: K1.PrivateKey) throws -> NotarizedSignedTransctionContext {
		try notarize(Engine.PrivateKey.secp256k1(notaryPrivateKey))
	}

	public func notarize(_ notaryPrivateKey: SLIP10.PrivateKey) throws -> NotarizedSignedTransctionContext {
		try notarize(notaryPrivateKey.intoEngine())
	}

	public func notarize(_ notaryPrivateKey: Engine.PrivateKey) throws -> NotarizedSignedTransctionContext {
		try sign(withMany: []) // a bit hacky, but hey, it works!
			.notarize(notaryPrivateKey)
	}
}
