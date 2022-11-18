import EngineToolkit
import Foundation
import Tagged

// MARK: - TransactionIntent.TXID
public extension TransactionIntent {
	// Move to EngineToolkit?
	typealias TXID = Tagged<Self, String>
}

public typealias TXID = TransactionIntent.TXID
