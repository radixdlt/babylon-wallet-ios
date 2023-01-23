import EngineToolkitModels
import Prelude

public extension P2P.ToDapp.WalletInteractionSuccessResponse {
	/// Response to Dapp from wallet, info about a signed and submitted transaction, see [CAP21][cap].
	///
	/// [cap]: https://radixdlt.atlassian.net/wiki/spaces/AT/pages/2712895489/CAP-21+Message+format+between+dApp+and+wallet#Wallet-SDK-%E2%86%94%EF%B8%8F-Wallet-messages
	///
	struct SendTransactionResponseItem: Sendable, Hashable, Encodable {
		public let transactionIntentHash: TXID

		public init(txID: TXID) {
			transactionIntentHash = txID
		}
	}
}
