import EngineToolkit
import Foundation
import SLIP10

// MARK: - BuildAndSignTransactionRequest
public struct BuildAndSignTransactionRequest: Sendable {
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

public extension BuildAndSignTransactionRequest {
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
