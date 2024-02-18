import EngineToolkit

public typealias TXID = TransactionHash

extension TXID {
	public var hex: String {
		bytes().hex()
	}
}
