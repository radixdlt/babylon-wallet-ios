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
			generateTXID: { transactionIntent in
				let compiledTransactionIntent = try compileTransactionIntent(transactionIntent)
				let hash = try blake2b(data: compiledTransactionIntent.compiledIntent)
				return TXID(rawValue: hash.hex)
			},
			accountAddressesNeedingToSignTransaction: { request throws -> Set<AccountAddress> in
				try Set(
					request.manifest.accountsRequiredToSign(
						networkId: request.networkID
					).map {
						try AccountAddress(componentAddress: $0)
					}
				)
			},
			accountAddressesSuitableToPayTransactionFee: { request throws -> Set<AccountAddress> in
				try Set(
					request.manifest.accountsSuitableToPayTXFee(
						networkId: request.networkID
					).map {
						try AccountAddress(componentAddress: $0)
					}
				)
			},
			knownEntityAddresses: { networkID throws -> KnownEntityAddressesResponse in
				try engineToolkit.knownEntityAddresses(request: .init(networkId: networkID)).get()
			},
			generateTransactionReview: { manifestWithPreviewContext in
				try engineToolkit.analyzeManifestWithPreviewContext(request: manifestWithPreviewContext).get()
			}
		)
	}()
}

// MARK: - FailedToConvertManifestToFormatWhereInstructionsAreJSON
struct FailedToConvertManifestToFormatWhereInstructionsAreJSON: Swift.Error {}

extension AccountAddress {
	public init(componentAddress: ComponentAddress) throws {
		try self.init(address: componentAddress.address)
	}
}
