import ClientPrelude
import Cryptography
@preconcurrency import EngineToolkit
import struct Profile.AccountAddress

extension EngineToolkitClient {
	public static let liveValue: Self = {
		let engineToolkit = EngineToolkit()

		let generateTXNonce: GenerateTXNonce = { Nonce.secureRandom() }

		let compileTransactionIntent: CompileTransactionIntent = { transactionIntent in
			try engineToolkit.compileTransactionIntentRequest(
				request: transactionIntent
			).get()
		}

		return Self(
			getTransactionVersion: { TXVersion.default },
			generateTXNonce: generateTXNonce,
			convertManifestInstructionsToJSONIfItWasString: { request in

				let converted = try engineToolkit.convertManifest(
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

			},
			compileTransactionIntent: compileTransactionIntent,
			compileSignedTransactionIntent: {
				try engineToolkit
					.compileSignedTransactionIntentRequest(request: $0)
					.get()
			},
			compileNotarizedTransactionIntent: {
				try engineToolkit.compileNotarizedTransactionIntentRequest(request: $0).get()
			},
			decompileTransactionIntent: {
				try engineToolkit.decompileTransactionIntentRequest(request: $0).get()
			},
			decompileNotarizedTransactionIntent: {
				try engineToolkit.decompileNotarizedTransactionIntentRequest(request: $0).get()
			},
			deriveOlympiaAdressFromPublicKey: {
				try engineToolkit.deriveOlympiaAddressFromPublicKeyRequest(
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
				try engineToolkit.knownEntityAddresses(request: .init(networkId: networkID)).get()
			},
			analyzeManifest: { request in
				let response = try engineToolkit.analyzeManifest(request: .init(manifest: request.manifest, networkId: request.networkID)).get()
				return try .init(response: response)
			},
			analyzeManifestWithPreviewContext: { manifestWithPreviewContext in
				try engineToolkit.analyzeManifestWithPreviewContext(request: manifestWithPreviewContext).get()
			},
			decodeAddress: { address in
				try engineToolkit.decodeAddressRequest(request: .init(address: address)).get()
			}
		)
	}()
}

// MARK: - FailedToConvertManifestToFormatWhereInstructionsAreJSON
struct FailedToConvertManifestToFormatWhereInstructionsAreJSON: Swift.Error {}
