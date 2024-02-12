import Foundation

// MARK: - TransactionHash
public typealias TXID = TransactionHash

// MARK: - TransactionHash
public struct TransactionHash: DummySargon {
	public func asStr() -> String {
		sargon()
	}

	public func bytes() -> [UInt8] {
		sargon()
	}
}
