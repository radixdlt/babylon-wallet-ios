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
		case closeButtonTapped
	}

	@Dependency(\.dismiss) var dismiss

	func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .closeButtonTapped:
			return .fireAndForget {
				await dismiss()
			}
		}
	}
}
