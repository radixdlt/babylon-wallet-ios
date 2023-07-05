import Prelude

// MARK: - TransactionIntent.TXID
extension TransactionIntent {
	// Move to EngineToolkit?
	public typealias TXID = Tagged<Self, String>
}

public typealias TXID = TransactionIntent.TXID
