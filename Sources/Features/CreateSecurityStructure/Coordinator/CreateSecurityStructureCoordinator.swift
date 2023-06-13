import AppPreferencesClient
import FeaturePrelude
import Profile

// MARK: - CreateSecurityStructureCoordinator
public struct CreateSecurityStructureCoordinator: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var mode: Mode
		public var root: Path.State
		public var path: StackState<Path.State> = []

		public enum Mode: Sendable, Hashable {
			case existing(SecurityStructureConfiguration)
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
			case start(CreateSecurityStructureStart.State)
			case simpleSetupFlow(SimpleCreateSecurityStructureFlow.State)
			case advancedSetupFlow(AdvancedCreateSecurityStructureFlow.State)
			case nameNewStructure(NameNewSecurityStructure.State)

			var simpleSetupFlow: SimpleCreateSecurityStructureFlow.State? {
				guard case let .simpleSetupFlow(simpleSetupFlow) = self else { return nil }
				return simpleSetupFlow
			}
		}

		public enum Action: Sendable, Equatable {
			case start(CreateSecurityStructureStart.Action)
			case simpleSetupFlow(SimpleCreateSecurityStructureFlow.Action)
			case advancedSetupFlow(AdvancedCreateSecurityStructureFlow.Action)
			case nameNewStructure(NameNewSecurityStructure.Action)
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
			Scope(state: /State.nameNewStructure, action: /Action.nameNewStructure) {
				NameNewSecurityStructure()
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

		case let .path(.element(_, action: .simpleSetupFlow(.delegate(.createSecurityStructure(simpleFlowResult))))):

			switch simpleFlowResult {
			case let .success(simple):
				let config = SecurityStructureConfiguration.Configuration(from: simple)
				state.path.append(.nameNewStructure(.init(configuration: config)))
			case let .failure(error):
				loggerGlobal.error("Failed to create simple security structure, error: \(error)")
				errorQueue.schedule(error)
			}

			return .none

		case let .path(.element(_, action: .simpleSetupFlow(.delegate(.updateExisting(updated))))):
			return .task {
				let taskResult = await TaskResult {
					try await appPreferencesClient.updating { preferences in
						let wasUpdated = preferences.security.structureConfigurations.updateOrAppend(updated) != nil
						assert(wasUpdated)
						return updated
					}
				}
				return .delegate(.done(taskResult))
			}

		case let .path(.element(_, action: .nameNewStructure(.delegate(.securityStructureCreationResult(result))))):
			return .send(.delegate(.done(result)))

		default: return .none
		}
	}
}

extension SecurityStructureConfiguration.Configuration {
	init(from simple: SimpleUnnamedSecurityStructureConfig) {
		self.init(
			primaryRole: .single(simple.singlePrimaryFactor),
			recoveryRole: .single(simple.singleRecoveryFactor),
			confirmationRole: .single(simple.singleConfirmationFactor)
		)
	}
}
