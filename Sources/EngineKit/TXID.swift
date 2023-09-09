import EngineToolkit
import Tagged

public typealias TXID = TransactionHash

extension TXID {
	public var hex: String {
		bytes().hex()
	}
}
