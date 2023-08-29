import FeaturePrelude
import OverlayWindowClient

// MARK: - Completion
struct Completion: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		let item: OverlayWindowClient.Item.DappInteractionSuccess

		init(
			item: OverlayWindowClient.Item.DappInteractionSuccess
		) {
			self.item = item
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
