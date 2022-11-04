import EngineToolkit
import Foundation
import SLIP10

// MARK: - BuildAndSignTransactionWithManifestRequest
public struct BuildAndSignTransactionWithManifestRequest: Sendable {
	public let privateKey: PrivateKey
	public let transactionHeaderInput: TransactionHeaderInput
	public let manifest: TransactionManifest

	public init(
		manifest: TransactionManifest,
		privateKey: PrivateKey,
		transactionHeaderInput: TransactionHeaderInput
	) {
		self.privateKey = privateKey
		self.transactionHeaderInput = transactionHeaderInput
		self.manifest = manifest
	}
}

public extension BuildAndSignTransactionWithManifestRequest {
	init(
		manifest: TransactionManifest,
		withoutManifestRequest: BuildAndSignTransactionWithoutManifestRequest
	) {
		self.init(
			manifest: manifest,
			privateKey: withoutManifestRequest.privateKey,
			transactionHeaderInput: withoutManifestRequest.transactionHeaderInput
		)
	}
}

public extension BuildAndSignTransactionWithManifestRequest {
	init(
		manifest: TransactionManifest,
		privateKey: PrivateKey,
		epoch: Epoch,
		networkID: NetworkID,
		costUnitLimit: UInt32 = TransactionHeaderInput.defaultCostUnitLimit
	) {
		self.init(
			manifest: manifest,
			privateKey: privateKey,
			transactionHeaderInput: .init(
				publicKey: privateKey.publicKey(),
				startEpoch: epoch,
				networkID: networkID,
				costUnitLimit: costUnitLimit
			)
		)
	}
}

// MARK: - BuildAndSignTransactionWithoutManifestRequest
public struct BuildAndSignTransactionWithoutManifestRequest: Sendable {
	public let privateKey: PrivateKey
	public let transactionHeaderInput: TransactionHeaderInput

	public init(
		privateKey: PrivateKey,
		transactionHeaderInput: TransactionHeaderInput
	) {
		self.privateKey = privateKey
		self.transactionHeaderInput = transactionHeaderInput
	}
}

public extension BuildAndSignTransactionWithoutManifestRequest {
	init(
		privateKey: PrivateKey,
		epoch: Epoch,
		networkID: NetworkID,
		costUnitLimit: UInt32 = TransactionHeaderInput.defaultCostUnitLimit
	) {
		self.init(
			privateKey: privateKey,
			transactionHeaderInput: .init(
				publicKey: privateKey.publicKey(),
				startEpoch: epoch,
				networkID: networkID,
				costUnitLimit: costUnitLimit
			)
		)
	}
}
