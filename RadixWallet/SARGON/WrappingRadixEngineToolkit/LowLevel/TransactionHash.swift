import Foundation

// MARK: - TransactionHash
public typealias TXID = TransactionHash

// MARK: - TransactionHash
public struct TransactionHash: DummySargon {
	public func asStr() -> String {
		panic()
	}

	public func bytes() -> [UInt8] {
		panic()
	}
}
