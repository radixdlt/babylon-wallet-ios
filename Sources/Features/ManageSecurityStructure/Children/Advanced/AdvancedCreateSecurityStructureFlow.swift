import FeaturePrelude

// MARK: - AdvancedManageSecurityStructureFlow
public struct AdvancedManageSecurityStructureFlow: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public enum Mode: Sendable, Hashable {
			case existing(SecurityStructureConfigurationDetailed)
			case new
		}

		public let existing: SecurityStructureConfigurationDetailed?

		public var primaryRole: SecurityStructureConfigurationDetailed.Configuration.Primary
		public var recoveryRole: SecurityStructureConfigurationDetailed.Configuration.Recovery
		public var confirmationRole: SecurityStructureConfigurationDetailed.Configuration.Confirmation

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
			case .new:
				self.existing = nil
				self.primaryRole = .init()
				self.recoveryRole = .init()
				self.confirmationRole = .init()
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
	}

	public enum ChildAction: Sendable, Equatable {
		case destination(PresentationAction<Destinations.Action>)
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
		case .primaryRoleButtonTapped:
			state.destination = .factorsForRole(.init(role: .primary))
			return .none

		case .recoveryRoleButtonTapped:
			state.destination = .factorsForRole(.init(role: .recovery))
			return .none

		case .confirmationRoleButtonTapped:
			state.destination = .factorsForRole(.init(role: .confirmation))
			return .none
		}
	}
}

extension RoleOfTier {
	public init() {
		self.init(
			thresholdFactors: .init(),
			threshold: 0,
			superAdminFactors: .init()
		)
	}
}
