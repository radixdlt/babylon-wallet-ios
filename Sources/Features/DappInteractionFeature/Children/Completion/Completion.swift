import EngineKit
import FeaturePrelude

// MARK: - Completion
struct Completion: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		let txID: TXID?
		let dappMetadata: DappMetadata

		init(
			txID: TXID?,
			dappMetadata: DappMetadata
		) {
			self.txID = txID
			self.dappMetadata = dappMetadata
		}
	}
}
