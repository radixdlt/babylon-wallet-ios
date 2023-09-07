import FeaturePrelude

// MARK: - Completion
struct Completion: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		let dappMetadata: DappMetadata

		init(
			dappMetadata: DappMetadata
		) {
			self.dappMetadata = dappMetadata
		}
	}
}
