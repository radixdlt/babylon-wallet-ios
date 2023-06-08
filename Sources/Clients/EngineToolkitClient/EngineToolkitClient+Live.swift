import ClientPrelude
import Cryptography
@preconcurrency import EngineToolkit
import struct Profile.AccountAddress

extension EngineToolkitClient {
	public static let liveValue: Self = {
		let generateTXNonce: GenerateTXNonce = { Nonce.secureRandom() }

		let compileTransactionIntent: CompileTransactionIntent = { transactionIntent in
			try RadixEngine.instance.compileTransactionIntentRequest(
				request: transactionIntent
			).get()
		}

		let convertManifestInstructionsToJSONIfItWasString: ConvertManifestInstructionsToJSONIfItWasString = { request in

			let converted = try RadixEngine.instance.convertManifest(
				request: .init(
					manifest: request.manifest,
					outputFormat: .parsed,
					networkId: request.networkID
				)
			)
			.get()

			guard case let .parsed(instructions) = converted.instructions else {
				throw FailedToConvertManifestToFormatWhereInstructionsAreJSON()
			}

			return JSONInstructionsTransactionManifest(
				instructions: instructions,
				convertedManifestThatContainsThem: converted
			)
		}

		return Self(
			getTransactionVersion: { TXVersion.default },
			generateTXNonce: generateTXNonce,
			convertManifestInstructionsToJSONIfItWasString: convertManifestInstructionsToJSONIfItWasString,
			convertManifestToString: { try RadixEngine.instance.convertManifest(request: .init(manifest: $0.manifest, outputFormat: .string, networkId: $0.networkID)).get() },
			compileTransactionIntent: compileTransactionIntent,
			compileSignedTransactionIntent: {
				try RadixEngine.instance
					.compileSignedTransactionIntentRequest(request: $0)
					.get()
			},
			compileNotarizedTransactionIntent: {
				try RadixEngine.instance.compileNotarizedTransactionIntentRequest(request: $0).get()
			},
			decompileTransactionIntent: {
				try RadixEngine.instance.decompileTransactionIntentRequest(request: $0).get()
			},
			decompileNotarizedTransactionIntent: {
				try RadixEngine.instance.decompileNotarizedTransactionIntentRequest(request: $0).get()
			},
			deriveOlympiaAdressFromPublicKey: {
				try RadixEngine.instance.deriveOlympiaAddressFromPublicKeyRequest(
					request: .init(network: .mainnet, publicKey: $0.intoEngine())
				)
				.get()
				.olympiaAccountAddress
			},
			generateTXID: { transactionIntent in
				let compiledTransactionIntent = try compileTransactionIntent(transactionIntent)
				let hash = try blake2b(data: compiledTransactionIntent.compiledIntent)
				return TXID(rawValue: hash.hex)
			},
			knownEntityAddresses: { networkID throws -> KnownEntityAddressesResponse in
				try RadixEngine.instance.knownEntityAddresses(request: .init(networkId: networkID)).get()
			},
			analyzeManifest: { request in
				try RadixEngine.instance.analyzeManifest(request: .init(manifest: request.manifest, networkId: request.networkID)).get()
			},
			analyzeManifestWithPreviewContext: { manifestWithPreviewContext in
				try RadixEngine.instance.analyzeManifestWithPreviewContext(request: manifestWithPreviewContext).get()
			},
			decodeAddress: { address in
				try RadixEngine.instance.decodeAddressRequest(request: .init(address: address)).get()
			}
		)
	}()
}

// MARK: - FailedToConvertManifestToFormatWhereInstructionsAreJSON
struct FailedToConvertManifestToFormatWhereInstructionsAreJSON: Swift.Error {}

extension SetMetadata {
	public static let ownerKeysKey = "owner_keys"
}
