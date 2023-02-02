import FeaturePrelude

// MARK: - DappInteraction
public struct DappInteractionLoading: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		let interaction: P2P.FromDapp.WalletInteraction

		public init(
			interaction: P2P.FromDapp.WalletInteraction
		) {
			self.interaction = interaction
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
	}

	public init() {}
}
