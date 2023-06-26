import FeaturePrelude

extension FactorSourceKind {
	public var isPrimaryRoleSupported: Bool {
		switch self {
		case .device, .ledgerHQHardwareWallet, .offDeviceMnemonic:
			return true
		case .trustedContact:
			return false
		case .securityQuestions:
			// This factor source kind is too cryptographically weak to be allowed for primary.
			return false
		}
	}

	public var isRecoveryRoleSupported: Bool {
		switch self {
		case .device:
			// If a user has lost her phone, how can she use it to perform recovery...she cant!
			return false
		case .ledgerHQHardwareWallet, .offDeviceMnemonic, .trustedContact:
			return true
		case .securityQuestions:
			// This factor source kind is too cryptographically weak to be allowed for recovery
			return false
		}
	}

	public var isConfirmationRoleSupported: Bool {
		switch self {
		case .device:
			return true
		case .ledgerHQHardwareWallet, .offDeviceMnemonic:
			return true
		case .trustedContact:
			return false
		case .securityQuestions:
			return true
		}
	}

	public func supports(
		role: SecurityStructureRole
	) -> Bool {
		switch role {
		case .primary: return isPrimaryRoleSupported
		case .recovery: return isRecoveryRoleSupported
		case .confirmation: return isConfirmationRoleSupported
		}
	}
}

extension Collection<FactorSource> {
	func filter(
		supportedByRole role: SecurityStructureRole
	) -> IdentifiedArrayOf<FactorSource> {
		.init(uncheckedUniqueElements: filter {
			$0.kind.supports(role: role)
		})
	}
}

// MARK: - FactorsForRole
public struct FactorsForRole: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var role: SecurityStructureRole
		public var threshold: UInt? = nil
		public var thresholdFactorSources: IdentifiedArrayOf<FactorSource> = []
		public var adminFactorSources: IdentifiedArrayOf<FactorSource> = []

		@PresentationState
		public var destination: Destinations.State?

		public init(
			role: SecurityStructureRole
		) {
			self.role = role
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case addAdminFactor
		case removeAdminFactor(FactorSourceID)
		case addThresholdFactor
		case removeThresholdFactor(FactorSourceID)

		case thresholdChanged(String)
	}

	public enum ChildAction: Sendable, Equatable {
		case destination(PresentationAction<Destinations.Action>)
	}

	public struct Destinations: Sendable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case addThresholdFactor(SelectFactorKindThenFactor.State)
			case addAdminFactor(SelectFactorKindThenFactor.State)
		}

		public enum Action: Sendable, Equatable {
			case addThresholdFactor(SelectFactorKindThenFactor.Action)
			case addAdminFactor(SelectFactorKindThenFactor.Action)
		}

		public init() {}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.addThresholdFactor, action: /Action.addThresholdFactor) {
				SelectFactorKindThenFactor()
			}
			Scope(state: /State.addAdminFactor, action: /Action.addAdminFactor) {
				SelectFactorKindThenFactor()
			}
		}
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
		case let .thresholdChanged(thresholdString):
			guard let threshold = UInt(thresholdString) else {
				return .none
			}
			state.threshold = threshold
			return .none

		case .addThresholdFactor:
			state.destination = .addThresholdFactor(.init())
			return .none

		case let .removeAdminFactor(factorSourceID):
			state.adminFactorSources[id: factorSourceID] = nil
			return .none

		case let .removeThresholdFactor(factorSourceID):
			state.thresholdFactorSources[id: factorSourceID] = nil
			return .none

		case .addAdminFactor:
			state.destination = .addAdminFactor(.init())
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .destination(.presented(.addAdminFactor(.delegate(.selected(adminFactorSource))))):
			state.adminFactorSources.append(adminFactorSource)
			state.destination = nil
			return .none

		case let .destination(.presented(.addThresholdFactor(.delegate(.selected(thresholdFactorSource))))):
			state.thresholdFactorSources.append(thresholdFactorSource)
			state.destination = nil
			return .none

		default:
			return .none
		}
	}
}
