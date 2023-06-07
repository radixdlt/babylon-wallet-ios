import FactorSourcesClient
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

			var simpleSetupFlow: SimpleCreateSecurityStructureFlow.State? {
				guard case let .simpleSetupFlow(simpleSetupFlow) = self else { return nil }
				return simpleSetupFlow
			}
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

	public enum DelegateAction: Sendable, Hashable {
		case done(TaskResult<SecurityStructureConfiguration>)
	}

	@Dependency(\.factorSourcesClient) var factorSourcesClient
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

		case let .path(.element(id, action: .simpleNewPhoneConfirmer(.delegate(.createdFactorSource(newPhoneConfirmer))))):
			// FIXME: uh.. this is terrible... hmm change to tree based navigation?
			guard
				let simpleSetupFlowIndex = state.path.firstIndex(where: { $0.simpleSetupFlow != nil }),
				var simpleSetupFlow = state.path[simpleSetupFlowIndex].simpleSetupFlow
			else {
				assertionFailure("Unexpectly where in wrong state..?")
				return .none
			}
			simpleSetupFlow.newPhoneConfirmer = newPhoneConfirmer
			state.path[simpleSetupFlowIndex] = .simpleSetupFlow(simpleSetupFlow)
			return .none

		case let .path(.element(_, action: .simpleSetupFlow(.delegate(.createSecurityStructure(simpleFactorConfig))))):
			return .task {
				let taskResult = await TaskResult {
					let primary = try await factorSourcesClient
						.getFactorSources(matching: {
							$0.kind == .device && !$0.supportsOlympia
						}).first!

					return SecurityStructureConfiguration(
						label: "Unnamed",
						configuration: .init(
							primaryRole: .single(primary),
							recoveryRole: .single(simpleFactorConfig.lostPhoneHelper.embed()),
							confirmationRole: .single(simpleFactorConfig.newPhoneConfirmer.embed())
						)
					)
				}
				return .delegate(.done(taskResult))
			}

		default: return .none
		}
	}
}
