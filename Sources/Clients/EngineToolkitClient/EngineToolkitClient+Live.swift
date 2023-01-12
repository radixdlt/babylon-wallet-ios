import Cryptography
@preconcurrency import EngineToolkit
import Prelude
import struct Profile.AccountAddress

public extension EngineToolkitClient {
	static let liveValue: Self = {
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
						transactionVersion: request.version,
						manifest: request.manifest,
						outputFormat: .json,
						networkId: request.networkID
					)
				)
				.get()

				guard case let .json(instructions) = converted.instructions else {
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
				let hash = Data(
					SHA256.twice(data: Data(compiledTransactionIntent.compiledIntent))
				)
				return TXID(rawValue: hash.hex)
			},
			accountAddressesNeedingToSignTransaction: { request throws -> Set<AccountAddress> in
				try Set(
					request.manifest.accountsRequiredToSign(
						networkId: request.networkID,
						version: request.version
					).map {
						try AccountAddress(componentAddress: $0)
					}
				)
			}
		)
	}()
}

// MARK: - FailedToConvertManifestToFormatWhereInstructionsAreJSON
struct FailedToConvertManifestToFormatWhereInstructionsAreJSON: Swift.Error {}

public extension AccountAddress {
	init(componentAddress: ComponentAddress) throws {
		try self.init(address: componentAddress.address)
	}
}
