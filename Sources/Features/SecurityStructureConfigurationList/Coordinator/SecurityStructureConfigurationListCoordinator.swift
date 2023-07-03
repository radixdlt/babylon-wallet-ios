import FeaturePrelude
import ManageSecurityStructureFeature

// MARK: - SecurityStructureConfigurationListCoordinator
public struct SecurityStructureConfigurationListCoordinator: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var configList: SecurityStructureConfigurationList.State

		@PresentationState
		public var destination: Destination.State? = nil

		public init(
			configList: SecurityStructureConfigurationList.State = .init()
		) {
			self.configList = configList
		}
	}

	public enum InternalAction: Sendable, Equatable {
		case loadDetailsForSecurityStructureResult(TaskResult<SecurityStructureConfigurationDetailed>)
	}

	public enum ChildAction: Sendable, Equatable {
		case configList(SecurityStructureConfigurationList.Action)
		case destination(PresentationAction<Destination.Action>)
	}

	// MARK: - Destination

	public struct Destination: ReducerProtocol {
		public enum State: Equatable, Hashable {
			case manageSecurityStructureCoordinator(ManageSecurityStructureCoordinator.State)
		}

		public enum Action: Equatable {
			case manageSecurityStructureCoordinator(ManageSecurityStructureCoordinator.Action)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(
				state: /State.manageSecurityStructureCoordinator,
				action: /Action.manageSecurityStructureCoordinator
			) {
				ManageSecurityStructureCoordinator()
			}
		}
	}

	// MARK: - Reducer

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.appPreferencesClient) var appPreferencesClient

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Scope(state: \.configList, action: /Action.child .. ChildAction.configList) {
			SecurityStructureConfigurationList()
		}
		Reduce(core)
			.ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destination()
			}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .loadDetailsForSecurityStructureResult(.success(config)):
			state.destination = .manageSecurityStructureCoordinator(.init(mode: .existing(config)))
			return .none
		case let .loadDetailsForSecurityStructureResult(.failure(error)):
			loggerGlobal.error("Failed to load details for security structure config reference, error: \(error)")
			errorQueue.schedule(error)
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case .configList(.delegate(.createNewStructure)):
			state.destination = .manageSecurityStructureCoordinator(.init())
			return .none

		case let .configList(.delegate(.displayDetails(configReference))):

			return .task {
				let taskResult = await TaskResult {
					try await appPreferencesClient.getDetailsOfSecurityStructure(configReference)
				}
				return .internal(.loadDetailsForSecurityStructureResult(taskResult))
			}

		case let .destination(.presented(.manageSecurityStructureCoordinator(.delegate(.done(.success(config)))))):
			let configReference = config.asReference()
			state.configList.configs[id: configReference.id] = .init(configReference: configReference)
			state.destination = nil
			return .none

		default:
			return .none
		}
	}
}
