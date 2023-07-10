import EngineToolkitUniFFI

// MARK: - TransactionIntent.TXID
extension Intent {
        public typealias TXID = Tagged<Intent, String>
}

public typealias TXID = Intent.TXID
