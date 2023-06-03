import FeaturePrelude
import Profile

// MARK: - CreateSecurityStructureCoordinator
public struct CreateSecurityStructureCoordinator: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		var root: Path.State?
		var path: StackState<Path.State> = []

		public init() {
			root = .start(.init())
		}
	}

	public struct Path: Sendable, Hashable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case start(CreateSecurityStructureStart.State)
			case simpleSetupFlow(SimpleCreateSecurityStructureFlow.State)
			case advancedSetupFlow(AdvancedCreateSecurityStructureFlow.State)

			case simpleLostPhoneHelper(SimpleLostPhoneHelper.State)
			case simpleNewPhoneConfirmer(SimpleNewPhoneConfirmer.State)
		}

		public enum Action: Sendable, Equatable {
			case start(CreateSecurityStructureStart.Action)
			case simpleSetupFlow(SimpleCreateSecurityStructureFlow.Action)
			case advancedSetupFlow(AdvancedCreateSecurityStructureFlow.Action)

			case simpleLostPhoneHelper(SimpleLostPhoneHelper.Action)
			case simpleNewPhoneConfirmer(SimpleNewPhoneConfirmer.Action)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.start, action: /Action.start) {
				CreateSecurityStructureStart()
			}
			Scope(state: /State.simpleSetupFlow, action: /Action.simpleSetupFlow) {
				SimpleCreateSecurityStructureFlow()
			}
			Scope(state: /State.advancedSetupFlow, action: /Action.advancedSetupFlow) {
				AdvancedCreateSecurityStructureFlow()
			}
			Scope(state: /State.simpleNewPhoneConfirmer, action: /Action.simpleNewPhoneConfirmer) {
				SimpleNewPhoneConfirmer()
			}
			Scope(state: /State.simpleLostPhoneHelper, action: /Action.simpleLostPhoneHelper) {
				SimpleLostPhoneHelper()
			}
		}
	}

	public enum ChildAction: Sendable, Equatable {
		case root(Path.Action)
		case path(StackAction<Path.Action>)
	}

	public init() {}

	public var body: some ReducerProtocolOf<CreateSecurityStructureCoordinator> {
		Reduce(core)
			.ifLet(\.root, action: /Action.child .. ChildAction.root) {
				Path()
			}
			.forEach(\.path, action: /Action.child .. ChildAction.path) {
				Path()
			}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case .root(.start(.delegate(.simpleFlow))):
			state.path.append(.simpleSetupFlow(.init()))
			return .none
		case .root(.start(.delegate(.advancedFlow))):
			state.path.append(.advancedSetupFlow(.init()))
			return .none

		case .path(.element(_, action: .simpleSetupFlow(.delegate(.selectNewPhoneConfirmer)))):
			state.path.append(.simpleNewPhoneConfirmer(.init()))
			return .none

		case .path(.element(_, action: .simpleSetupFlow(.delegate(.selectLostPhoneHelper)))):
			state.path.append(.simpleLostPhoneHelper(.init()))
			return .none

		default: return .none
		}
	}
}
