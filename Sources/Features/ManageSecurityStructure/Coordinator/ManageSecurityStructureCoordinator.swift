import AppPreferencesClient
import FeaturePrelude
import Profile

// MARK: - ManageSecurityStructureCoordinator
public struct ManageSecurityStructureCoordinator: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var mode: Mode
		public var root: Path.State
		public var path: StackState<Path.State> = []

		public enum Mode: Sendable, Hashable {
			case existing(SecurityStructureConfigurationDetailed)
			case new
		}

		public init(mode: Mode = .new) {
			self.mode = mode
			switch mode {
			case let .existing(config) where config.isSimple:
				self.root = .simpleSetupFlow(.init(mode: .existing(config)))
			case let .existing(config) where !config.isSimple:
				self.root = .advancedSetupFlow(.init(mode: .existing(config)))
			case .existing: preconditionFailure("Already handled above")
			case .new:
				self.root = .start(.init())
			}
		}
	}

	public struct Path: Sendable, Hashable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case start(ManageSecurityStructureStart.State)
			case simpleSetupFlow(SimpleManageSecurityStructureFlow.State)
			case advancedSetupFlow(AdvancedManageSecurityStructureFlow.State)
			case nameStructure(NameSecurityStructure.State)

			var simpleSetupFlow: SimpleManageSecurityStructureFlow.State? {
				guard case let .simpleSetupFlow(simpleSetupFlow) = self else { return nil }
				return simpleSetupFlow
			}
		}

		public enum Action: Sendable, Equatable {
			case start(ManageSecurityStructureStart.Action)
			case simpleSetupFlow(SimpleManageSecurityStructureFlow.Action)
			case advancedSetupFlow(AdvancedManageSecurityStructureFlow.Action)
			case nameStructure(NameSecurityStructure.Action)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.start, action: /Action.start) {
				ManageSecurityStructureStart()
			}
			Scope(state: /State.simpleSetupFlow, action: /Action.simpleSetupFlow) {
				SimpleManageSecurityStructureFlow()
			}
			Scope(state: /State.advancedSetupFlow, action: /Action.advancedSetupFlow) {
				AdvancedManageSecurityStructureFlow()
			}
			Scope(state: /State.nameStructure, action: /Action.nameStructure) {
				NameSecurityStructure()
			}
		}
	}

	public enum ChildAction: Sendable, Equatable {
		case root(Path.Action)
		case path(StackAction<Path.Action>)
	}

	public enum DelegateAction: Sendable, Hashable {
		case done(TaskResult<SecurityStructureConfigurationDetailed>)
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.appPreferencesClient) var appPreferencesClient
	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Scope(state: \.root, action: /Action.child .. ChildAction.root) {
			Path()
		}

		Reduce(core)
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
			state.path.append(.advancedSetupFlow(.init(mode: .new(.init()))))
			return .none

		case
			let .path(.element(_, action: .simpleSetupFlow(.delegate(.updatedOrCreatedSecurityStructure(simpleFlowResult))))),
			let .root(.simpleSetupFlow(.delegate(.updatedOrCreatedSecurityStructure(simpleFlowResult)))):

			switch simpleFlowResult {
			case let .success(product):
				switch product {
				case let .creatingNew(newConfig):
					state.path.append(.nameStructure(.name(new: newConfig)))
				case let .updating(existingStructure):
					state.path.append(.nameStructure(.updateName(of: existingStructure)))
				}
			case let .failure(error):
				loggerGlobal.error("Failed to create simple security structure, error: \(error)")
				errorQueue.schedule(error)
			}

			return .none

		case let .path(.element(_, action: .nameStructure(.delegate(.updateOrCreateSecurityStructure(structure))))):

			return .task { [isUpdatingExisting = state.mode == .new] in
				let taskResult = await TaskResult {
					let configReference = structure.asReference()
					try await appPreferencesClient.updating { preferences in
						let didUpdateExisting = preferences.security.structureConfigurationReferences.updateOrAppend(configReference) != nil
						assert(didUpdateExisting == isUpdatingExisting)
					}
					return structure
				}
				return .delegate(.done(taskResult))
			}

		default: return .none
		}
	}
}
