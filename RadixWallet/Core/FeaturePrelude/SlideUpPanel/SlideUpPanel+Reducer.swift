
// MARK: - SlideUpPanel
public struct SlideUpPanel: Sendable, FeatureReducer {
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

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .closeButtonTapped, .willDisappear:
			.send(.delegate(.dismiss))
		}
	}
}
