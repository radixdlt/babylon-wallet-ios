import FeaturePrelude

// MARK: - DappInteraction.State
public extension DappInteraction {
	struct State: Sendable, Equatable {
		let interaction: P2P.FromDapp.WalletInteraction

		@NavigationStateOf<Destinations>
		var navigation: NavigationState<Destinations.State>.Path

		public init(
			interaction: P2P.FromDapp.WalletInteraction
		) {
			self.interaction = interaction
		}
	}
}

#if DEBUG
public extension DappInteraction.State {
	static let previewValue: Self = .init(
		interaction: .previewValueOneTimeAccount
	)
}
#endif
