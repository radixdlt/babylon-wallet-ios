import Common
import CryptoKit
import Dependencies
@preconcurrency import EngineToolkit
import Foundation
import struct Profile.AccountAddress
import enum SLIP10.PrivateKey
import enum SLIP10.PublicKey

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
			getTransactionVersion: { Version.default },
			generateTXNonce: generateTXNonce,
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

public extension AccountAddress {
	init(componentAddress: ComponentAddress) throws {
		try self.init(address: componentAddress.address)
	}
}
