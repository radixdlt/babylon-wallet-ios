import FeaturePrelude

// MARK: - AdvancedManageSecurityStructureFlow
public struct AdvancedManageSecurityStructureFlow: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public enum Mode: Sendable, Hashable {
			case existing(SecurityStructureConfigurationDetailed)
			case new
		}

		public let existing: SecurityStructureConfigurationDetailed?

		public typealias Role = SecurityStructureConfigurationDetailed.Configuration.Role
		public var primaryRole: Role? = nil
		public var recoveryRole: Role? = nil
		public var confirmationRole: Role? = nil
		public var numberOfDaysUntilAutoConfirmation: RecoveryAutoConfirmDelayInDays

		public var config: SecurityStructureConfigurationDetailed.Configuration?

		@PresentationState
		var destination: Destinations.State? = nil

		public init(mode: Mode) {
			switch mode {
			case let .existing(existing):
				self.existing = existing
				let config = existing.configuration
				self.primaryRole = config.primaryRole
				self.recoveryRole = config.recoveryRole
				self.confirmationRole = config.confirmationRole
				self.numberOfDaysUntilAutoConfirmation = config.numberOfDaysUntilAutoConfirmation
			case .new:
				self.existing = nil
				self.numberOfDaysUntilAutoConfirmation = SecurityStructureConfigurationReference.Configuration.Role.defaultNumberOfDaysUntilAutoConfirmation
			}
		}
	}

	public struct Destinations: Sendable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case factorsForRole(FactorsForRole.State)
		}

		public enum Action: Sendable, Equatable {
			case factorsForRole(FactorsForRole.Action)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.factorsForRole, action: /Action.factorsForRole) {
				FactorsForRole()
			}
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case primaryRoleButtonTapped
		case recoveryRoleButtonTapped
		case confirmationRoleButtonTapped

		case changedNumberOfDaysUntilAutoConfirmation(String)
		case finished(SecurityStructureConfigurationDetailed.Configuration)
	}

	public enum ChildAction: Sendable, Equatable {
		case destination(PresentationAction<Destinations.Action>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case updatedOrCreatedSecurityStructure(TaskResult<SecurityStructureProduct>)
	}

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destinations()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case let .changedNumberOfDaysUntilAutoConfirmation(delayAsString):

			guard
				let raw = RecoveryAutoConfirmDelayInDays.RawValue(delayAsString)
			else {
				return .none
			}
			let delay = RecoveryAutoConfirmDelayInDays(rawValue: raw)
			state.numberOfDaysUntilAutoConfirmation = delay
			createConfigIfAble(&state)
			return .none

		case .primaryRoleButtonTapped:
			state.destination = .factorsForRole(.init(role: .primary))
			return .none

		case .recoveryRoleButtonTapped:
			state.destination = .factorsForRole(.init(role: .recovery))
			return .none

		case .confirmationRoleButtonTapped:
			state.destination = .factorsForRole(.init(role: .confirmation))
			return .none

		case let .finished(config):
			assert(config == state.config)
			if var structureToUpdate = state.existing {
				structureToUpdate.configuration = config
				return .send(.delegate(.updatedOrCreatedSecurityStructure(.success(.updating(structure: structureToUpdate)))))
			} else {
				return .send(.delegate(.updatedOrCreatedSecurityStructure(.success(.creatingNew(config: config)))))
			}
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .destination(.presented(.factorsForRole(.delegate(.confirmedRoleWithFactors(roleWithFactors))))):
			switch roleWithFactors.role {
			case .confirmation:
				state.confirmationRole = roleWithFactors.factors
			case .primary:
				state.primaryRole = roleWithFactors.factors
			case .recovery:
				state.recoveryRole = roleWithFactors.factors
			}
			state.destination = nil
			createConfigIfAble(&state)
			return .none

		default:
			return .none
		}
	}

	func createConfigIfAble(_ state: inout State) {
		guard
			let primary = state.primaryRole,
			let recovery = state.recoveryRole,
			let confirmation = state.confirmationRole
		else {
			return
		}

		state.config = .init(
			numberOfDaysUntilAutoConfirmation: state.numberOfDaysUntilAutoConfirmation,
			primaryRole: primary,
			recoveryRole: recovery,
			confirmationRole: confirmation
		)
	}
}

extension RoleOfTier {
	public init(role: SecurityStructureRole) {
		try! self.init(
			role: role,
			thresholdFactors: .init(),
			threshold: 0,
			superAdminFactors: .init()
		)
	}
}
