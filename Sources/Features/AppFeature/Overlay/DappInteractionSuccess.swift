import FeaturePrelude
import OverlayWindowClient

// MARK: - Completion
public struct DappInteractionSuccess: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let item: OverlayWindowClient.Item.DappInteractionSuccess

		public init(
			item: OverlayWindowClient.Item.DappInteractionSuccess
		) {
			self.item = item
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case closeButtonTapped
	}

	@Dependency(\.dismiss) var dismiss

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .closeButtonTapped:
			return .fireAndForget {
				await dismiss()
			}
		}
	}
}
