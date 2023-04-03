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

	public enum ChildAction: Sendable, Equatable {
		case infoPanel(PresentationAction<SlideUpPanel.Action>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case done
	}

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		EmptyReducer()
			.ifLet(\.$infoPanel, action: /Action.child .. ChildAction.infoPanel) {
				SlideUpPanel()
			}

		Reduce(self.core)
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case .infoPanel(.presented(.delegate(.dismiss))):
			state.infoPanel = nil
			return .none
		default:
			return .none
		}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .none
		case .showTutorial:
//			state.infoPanel = .init(
//				title: "Learn about Personas",
//				explanation: "Info about personas"
//			)

			// FIXME: display what is a gateway once we have copy
			loggerGlobal.warning("Learn about Personas tutorial slide up panel skipped, since no copy.")
			return .none
		case .continueButtonTapped:
			return .send(.delegate(.done))
		}
	}
}
