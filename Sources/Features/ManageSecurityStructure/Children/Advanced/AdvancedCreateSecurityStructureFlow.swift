import FeaturePrelude

// MARK: - AdvancedManageSecurityStructureFlow
public struct AdvancedManageSecurityStructureFlow: Sendable, FeatureReducer {
	public typealias Primary = FactorsForRole<PrimaryRoleTag>
	public typealias Recovery = FactorsForRole<RecoveryRoleTag>
	public typealias Confirmation = FactorsForRole<ConfirmationRoleTag>

	public struct State: Sendable, Hashable {
		public enum Mode: Sendable, Hashable {
			case existing(SecurityStructureConfigurationDetailed)
			case new
		}

		public let existing: SecurityStructureConfigurationDetailed?

		public var primaryRole: Primary.State
		public var recoveryRole: Recovery.State
		public var confirmationRole: Confirmation.State

		public init(mode: Mode) {
			switch mode {
			case let .existing(existing):
				self.existing = existing
				let config = existing.configuration
				self.primaryRole = .init(role: config.primaryRole)
				self.recoveryRole = .init(role: config.recoveryRole)
				self.confirmationRole = .init(role: config.confirmationRole)
			case .new:
				self.existing = nil
				self.primaryRole = .init(role: .init())
				self.recoveryRole = .init(role: .init())
				self.confirmationRole = .init(role: .init())
			}
		}
	}

	public enum ChildAction: Sendable, Equatable {
		case primaryRole(Primary.Action)
		case recoveryRole(Recovery.Action)
		case confirmationRole(Confirmation.Action)
	}

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Scope(
			state: \State.primaryRole,
			action: /Action.child .. ChildAction.primaryRole
		) {
			Primary()
		}

		Scope(
			state: \State.recoveryRole,
			action: /Action.child .. ChildAction.recoveryRole
		) {
			Recovery()
		}

		Scope(
			state: \State.confirmationRole,
			action: /Action.child .. ChildAction.confirmationRole
		) {
			Confirmation()
		}

		Reduce(core)
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
