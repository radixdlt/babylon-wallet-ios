import FeaturePrelude

// MARK: - AdvancedManageSecurityStructureFlow
public struct AdvancedManageSecurityStructureFlow: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public enum Mode: Sendable, Hashable {
			case existing(SecurityStructureConfigurationDetailed)
			case new(New = .init())

			public struct New: Sendable, Hashable {
				public var confirmationRole: SecurityStructureConfigurationDetailed.Configuration.Confirmation

				public init(
					confirmationRole: SecurityStructureConfigurationDetailed.Configuration.Confirmation = .init()
				) {
					self.confirmationRole = confirmationRole
				}
			}
		}

		public var mode: Mode

		public init(mode: Mode) {
			self.mode = mode
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case confirmationRoleFactorsButtonTapped
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .confirmationRoleFactorsButtonTapped:
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
