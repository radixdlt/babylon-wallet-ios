import Foundation

// MARK: - TransactionHeader
public struct TransactionHeader: DummySargon {
	public init(
		networkId: UInt8,
		startEpochInclusive: UInt64,
		endEpochExclusive: UInt64,
		nonce: UInt32,
		notaryPublicKey: Any,
		notaryIsSignatory: Bool,
		tipPercentage: Any
	) {
		sargon()
	}

	public var networkId: UInt8 {
		sargon()
	}

	public var startEpochInclusive: UInt64 {
		sargon()
	}

	public var endEpochExclusive: UInt64 {
		sargon()
	}

	public var notaryIsSignatory: Bool {
		sargon()
	}

	public var notaryPublicKey: SLIP10.PublicKey {
		sargon()
	}

	public var nonce: UInt32 {
		sargon()
	}

	public var tipPercentage: Float {
		sargon()
	}

	public func description(lookupNetworkName: (NetworkID) throws -> Void) rethrows -> String {
		sargon()
	}
}
