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
		panic()
	}

	public var networkId: UInt8 {
		panic()
	}

	public var startEpochInclusive: UInt64 {
		panic()
	}

	public var endEpochExclusive: UInt64 {
		panic()
	}

	public var notaryIsSignatory: Bool {
		panic()
	}

	public var notaryPublicKey: SLIP10.PublicKey {
		panic()
	}

	public var nonce: UInt32 {
		panic()
	}

	public var tipPercentage: Float {
		panic()
	}

	public func description(lookupNetworkName: (NetworkID) throws -> Void) rethrows -> String {
		panic()
	}
}
