import FeaturePrelude
import Profile

// MARK: - CreateSecurityStructureCoordinator
public struct CreateSecurityStructureCoordinator: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		var root: Path.State?
		var path: StackState<Path.State> = []

		public init() {}
	}

	public struct Path: Sendable, Hashable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case simpleSetupFlow(SimpleCreateSecurityStructureFlow.State)
			case advancedSetupFlow(AdvancedCreateSecurityStructureFlow.State)
		}

		public enum Action: Sendable, Equatable {
			case simpleSetupFlow(SimpleCreateSecurityStructureFlow.Action)
			case advancedSetupFlow(AdvancedCreateSecurityStructureFlow.Action)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.simpleSetupFlow, action: /Action.simpleSetupFlow) {
				SimpleCreateSecurityStructureFlow()
			}
			Scope(state: /State.advancedSetupFlow, action: /Action.advancedSetupFlow) {
				AdvancedCreateSecurityStructureFlow()
			}
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case simpleFlow
		case advancedFlow
	}

	public enum ChildAction: Sendable, Equatable {
		case root(Path.Action)
		case path(StackAction<Path.Action>)
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .simpleFlow:
			state.path.append(.simpleSetupFlow(.init()))
			return .none
		case .advancedFlow:
			state.path.append(.simpleSetupFlow(.init()))
			return .none
		}
	}
}
