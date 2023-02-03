import FeaturePrelude

// MARK: - DappInteraction
struct DappInteractionLoading: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		let interaction: P2P.FromDapp.WalletInteraction

		init(
			interaction: P2P.FromDapp.WalletInteraction
		) {
			self.interaction = interaction
		}
	}

	enum ViewAction: Sendable, Equatable {
		case appeared
	}
}
