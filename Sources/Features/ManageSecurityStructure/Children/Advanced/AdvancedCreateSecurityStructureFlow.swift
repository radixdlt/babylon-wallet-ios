import FeaturePrelude

// MARK: - AdvancedManageSecurityStructureFlow
public struct AdvancedManageSecurityStructureFlow: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public enum Mode: Sendable, Hashable {
			case existing(SecurityStructureConfigurationDetailed)
			case new
		}

		public let existing: SecurityStructureConfigurationDetailed?

		public var primaryRole: SecurityStructureConfigurationDetailed.Configuration.Primary?
		public var recoveryRole: SecurityStructureConfigurationDetailed.Configuration.Recovery?
		public var confirmationRole: SecurityStructureConfigurationDetailed.Configuration.Confirmation?
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
				self.numberOfDaysUntilAutoConfirmation = SecurityStructureConfigurationReference.Configuration.Recovery.defaultNumberOfDaysUntilAutoConfirmation
				self.primaryRole = nil
				self.recoveryRole = nil
				self.confirmationRole = nil
			}
		}
	}

	public struct Destinations: Sendable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case factorsForPrimaryRole(FactorsForRole<PrimaryRoleTag>.State)
			case factorsForRecoveryRole(FactorsForRole<RecoveryRoleTag>.State)
			case factorsForConfirmationRole(FactorsForRole<ConfirmationRoleTag>.State)
		}

		public enum Action: Sendable, Equatable {
			case factorsForPrimaryRole(FactorsForRole<PrimaryRoleTag>.Action)
			case factorsForRecoveryRole(FactorsForRole<RecoveryRoleTag>.Action)
			case factorsForConfirmationRole(FactorsForRole<ConfirmationRoleTag>.Action)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.factorsForPrimaryRole, action: /Action.factorsForPrimaryRole) {
				FactorsForRole<PrimaryRoleTag>()
			}
			Scope(state: /State.factorsForRecoveryRole, action: /Action.factorsForRecoveryRole) {
				FactorsForRole<RecoveryRoleTag>()
			}
			Scope(state: /State.factorsForConfirmationRole, action: /Action.factorsForConfirmationRole) {
				FactorsForRole<ConfirmationRoleTag>()
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
			state.destination = .factorsForPrimaryRole(.init(role: .primary, factors: state.primaryRole))
			return .none

		case .recoveryRoleButtonTapped:
			state.destination = .factorsForRecoveryRole(.init(role: .recovery, factors: state.recoveryRole))
			return .none

		case .confirmationRoleButtonTapped:
			state.destination = .factorsForConfirmationRole(.init(role: .confirmation, factors: state.confirmationRole))
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
		case let .destination(.presented(.factorsForPrimaryRole(.delegate(.confirmedRoleWithFactors(primaryRole))))):
			state.primaryRole = primaryRole
			state.destination = nil
			return .none

		case let .destination(.presented(.factorsForRecoveryRole(.delegate(.confirmedRoleWithFactors(recoveryRole))))):
			state.recoveryRole = recoveryRole
			state.destination = nil
			return .none

		case let .destination(.presented(.factorsForConfirmationRole(.delegate(.confirmedRoleWithFactors(confirmationRole))))):
			state.confirmationRole = confirmationRole
			state.destination = nil
			return .none

		default:
			return .none
		}
	}
}
