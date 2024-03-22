import EngineToolkit

public typealias TXID = TransactionHash

extension TXID {
	public func formatted(_ format: AddressFormat = .default) -> String {
		asStr()
	}

	public var hex: String {
		bytes().hex()
	}
}
