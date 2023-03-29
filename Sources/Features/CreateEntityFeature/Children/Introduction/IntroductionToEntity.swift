import FeaturePrelude

// MARK: - IntroductionToEntity
public struct IntroductionToEntity<Entity: EntityProtocol>: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		@PresentationState
		public var infoPanel: SlideUpPanel.State?
		public init() {}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case continueButtonTapped
		case showTutorial
	}

	public enum DelegateAction: Sendable, Equatable {
		case done
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .none
		case .showTutorial:
			loggerGlobal.info("Tutorial button ignore for now.")
			return .none
		case .continueButtonTapped:
			return .send(.delegate(.done))
		}
	}
}
