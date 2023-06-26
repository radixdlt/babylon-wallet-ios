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
		public var primaryRole: Role?
		public var recoveryRole: Role?
		public var confirmationRole: Role?
		public var numberOfDaysUntilAutoConfirmation: RecoveryAutoConfirmDelayInDays

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
				self.primaryRole = nil
				self.recoveryRole = nil
				self.confirmationRole = nil
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
			return .none

		case .primaryRoleButtonTapped:
			state.destination = .factorsForRole(.init(role: .primary, factors: state.primaryRole))
			return .none

		case .recoveryRoleButtonTapped:
			state.destination = .factorsForRole(.init(role: .recovery, factors: state.recoveryRole))
			return .none

		case .confirmationRoleButtonTapped:
			state.destination = .factorsForRole(.init(role: .confirmation, factors: state.confirmationRole))
			return .none

		case let .finished(config):
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
			return .none

		default:
			return .none
		}
	}
}
