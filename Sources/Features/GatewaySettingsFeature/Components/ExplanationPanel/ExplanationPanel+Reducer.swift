import FeaturePrelude

// MARK: - ExplanationPanel
public struct ExplanationPanel: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		var title: String
		var explanation: String

		public init(
			title: String,
			explanation: String
		) {
			self.title = title
			self.explanation = explanation
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case closeButtonTapped
		case willDisappear
	}

	public enum DelegateAction: Sendable, Equatable {
		case dismiss
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .closeButtonTapped, .willDisappear:
			return .send(.delegate(.dismiss))
		}
	}
}
