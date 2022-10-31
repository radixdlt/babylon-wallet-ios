import EngineToolkit
import Foundation
import SLIP10

// MARK: - TransactionHeaderInput
public struct TransactionHeaderInput: Sendable {
	public static let defaultCostUnitLimit: UInt32 = 10_000_000
	public let publicKey: PublicKey

	/// Fetch from GatewayAPI
	public let startEpoch: Epoch

	public let networkID: NetworkID
	public let costUnitLimit: UInt32

	public init(
		publicKey: PublicKey,
		startEpoch: Epoch,
		networkID: NetworkID,
		costUnitLimit: UInt32 = Self.defaultCostUnitLimit
	) {
		self.publicKey = publicKey
		self.startEpoch = startEpoch
		self.networkID = networkID
		self.costUnitLimit = costUnitLimit
	}
}

public extension TransactionHeaderInput {
	func header(
		epochDuration: Epoch = 2,
		version: Version = 1,
		nonce: @autoclosure () -> Nonce = Nonce.secureRandom(),
		notaryAsSignatory: Bool = true
	) throws -> TransactionHeader {
		try .init(
			version: version,
			networkId: networkID,
			startEpochInclusive: startEpoch,
			endEpochExclusive: startEpoch + epochDuration,
			nonce: nonce(),
			publicKey: publicKey.intoEngine(),
			notaryAsSignatory: notaryAsSignatory,
			costUnitLimit: costUnitLimit,
			tipPercentage: 0
		)
	}
}
