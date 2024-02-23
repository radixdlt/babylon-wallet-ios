import EngineToolkit

public typealias TXID = TransactionHash

extension TXID {
	public func formatted(_ format: AddressFormat = .default) -> String {
		bytes().hex()
	}

	public var hex: String {
		bytes().hex()
	}
}
