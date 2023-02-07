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

	enum ViewAction: Sendable, Equatable {
		case appeared
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		.none
	}
}
