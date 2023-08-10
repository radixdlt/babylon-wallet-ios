import FeaturePrelude

public struct LSUDetails: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		let stake: Int
	}

	@Dependency(\.dismiss) var dismiss

	public enum ViewAction: Sendable, Equatable {
		case closeButtonTapped
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .closeButtonTapped:
			return .run { _ in
				await dismiss()
			}
		}
	}
}
