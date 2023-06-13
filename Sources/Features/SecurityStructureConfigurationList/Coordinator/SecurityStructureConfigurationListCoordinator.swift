import CreateSecurityStructureFeature
import FeaturePrelude

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

	public enum ChildAction: Sendable, Equatable {
		case configList(SecurityStructureConfigurationList.Action)
		case destination(PresentationAction<Destination.Action>)
	}

	// MARK: - Destination

	public struct Destination: ReducerProtocol {
		public enum State: Equatable, Hashable {
			case createSecurityStructureConfig(CreateSecurityStructureCoordinator.State)
			case securityStructureConfigDetails(SecurityStructureConfigDetails.State)
		}

		public enum Action: Equatable {
			case createSecurityStructureConfig(CreateSecurityStructureCoordinator.Action)
			case securityStructureConfigDetails(SecurityStructureConfigDetails.Action)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.createSecurityStructureConfig, action: /Action.createSecurityStructureConfig) {
				CreateSecurityStructureCoordinator()
			}
			Scope(state: /State.securityStructureConfigDetails, action: /Action.securityStructureConfigDetails) {
				SecurityStructureConfigDetails()
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

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case .configList(.delegate(.createNewStructure)):
			state.destination = .createSecurityStructureConfig(.init())
			return .none

		case let .configList(.delegate(.displayDetails(config))):
			state.destination = .securityStructureConfigDetails(.init(config: config))
			return .none

		case let .destination(.presented(.createSecurityStructureConfig(.delegate(.done(.success(config)))))):
			state.configList.configs.append(.init(config: config))
			state.destination = nil
			return .none

		default:
			return .none
		}
	}
}
