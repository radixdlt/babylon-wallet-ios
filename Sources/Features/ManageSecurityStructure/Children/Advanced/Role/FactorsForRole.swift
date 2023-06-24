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
//		public let supportedFactorSources: IdentifiedArrayOf<FactorSource>
		public var threshold: UInt? = nil
		public var thresholdFactorSources: IdentifiedArrayOf<FactorSource> = []

		public init(
			//			allFactorSources: some Collection<FactorSource>,
			role: SecurityStructureRole
		) {
			self.role = role
//			self.supportedFactorSources = allFactorSources.filter(supportedByRole: role)
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case thresholdChanged(String)
		case setFactorsButtonTapped
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .none

		case let .thresholdChanged(thresholdString):
			guard let threshold = UInt(thresholdString) else {
				return .none
			}
			state.threshold = threshold
			return .none

		case .setFactorsButtonTapped:
			debugPrint("Set factors tapped")
			return .none
		}
	}
}
