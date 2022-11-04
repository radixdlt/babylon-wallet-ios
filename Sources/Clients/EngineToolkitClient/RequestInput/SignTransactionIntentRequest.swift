import EngineToolkit
import Foundation
import SLIP10

// MARK: - NonMatchingPrivateAndPublicKey
struct NonMatchingPrivateAndPublicKey: Swift.Error {}

// MARK: - SignTransactionIntentRequest
public struct SignTransactionIntentRequest: Sendable {
	public let transactionIntent: TransactionIntent
	public let privateKey: PrivateKey

	public init(
		transactionIntent: TransactionIntent,
		privateKey: PrivateKey
	) throws {
		assert(!transactionIntent.manifest.blobs.isEmpty) // FIXME: Remove post E2E
		let expectedPublicKey = try privateKey.publicKey().intoEngine()
		guard
			transactionIntent.header.publicKey == expectedPublicKey
		else {
			throw NonMatchingPrivateAndPublicKey()
		}
		self.transactionIntent = transactionIntent
		self.privateKey = privateKey
	}
}

public extension SignTransactionIntentRequest {
	var version: Version {
		transactionIntent.header.version
	}

	var networkID: NetworkID {
		transactionIntent.header.networkId
	}
}

public extension SignTransactionIntentRequest {
	init(
		manifest: TransactionManifest,
		header: TransactionHeader,
		privateKey: PrivateKey
	) throws {
		try self.init(
			transactionIntent: .init(
				header: header,
				manifest: manifest
			),
			privateKey: privateKey
		)
	}

	init(
		manifest: TransactionManifest,
		headerInput: TransactionHeaderInput,
		privateKey: PrivateKey
	) throws {
		try self.init(
			transactionIntent: .init(
				header: headerInput.header(),
				manifest: manifest
			),
			privateKey: privateKey
		)
	}

	init(
		manifest: TransactionManifest,
		privateKey: PrivateKey,
		epoch: Epoch,
		networkID: NetworkID,
		costUnitLimit _: UInt32 = TransactionHeaderInput.defaultCostUnitLimit
	) throws {
		let headerInput = TransactionHeaderInput(
			publicKey: privateKey.publicKey(),
			startEpoch: epoch,
			networkID: networkID
		)

		try self.init(
			manifest: manifest,
			headerInput: headerInput,
			privateKey: privateKey
		)
	}
}
