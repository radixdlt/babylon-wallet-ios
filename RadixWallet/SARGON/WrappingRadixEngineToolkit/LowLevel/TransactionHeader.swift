import Foundation

// MARK: - TransactionHeader
public struct TransactionHeader: DummySargon {
	public init(
		networkId: NetworkID,
		startEpochInclusive: Epoch,
		endEpochExclusive: Epoch,
		nonce: Nonce,
		notaryPublicKey: SLIP10.PublicKey,
		notaryIsSignatory: Bool,
		tipPercentage: UInt16
	) {
		sargon()
	}

	public var networkId: NetworkID {
		sargon()
	}

	public var startEpochInclusive: Epoch {
		sargon()
	}

	public var endEpochExclusive: Epoch {
		sargon()
	}

	public var notaryIsSignatory: Bool {
		sargon()
	}

	public var notaryPublicKey: SLIP10.PublicKey {
		sargon()
	}

	public var nonce: Nonce {
		sargon()
	}

	public var tipPercentage: UInt16 {
		sargon()
	}
}
