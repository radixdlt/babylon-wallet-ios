import Prelude

// MARK: - SupportedUsageForRole
public enum SupportedUsageForRole: Sendable, Hashable {
	/// Either alone or combined with other
	case aloneOrWhenCombinedWithOther

	/// Not alone, only together with another FactorSourceKind
	case onlyWhenCombinedWithOther
}

extension FactorSourceKind {
	public var supportedUsageForPrimaryRole: SupportedUsageForRole? {
		switch self {
		case .device:
			return .aloneOrWhenCombinedWithOther

		case .ledgerHQHardwareWallet:
			return .aloneOrWhenCombinedWithOther

		case .offDeviceMnemonic:
			return .aloneOrWhenCombinedWithOther

		case .trustedContact:
			return nil

		case .securityQuestions:
			return .onlyWhenCombinedWithOther
		}
	}

	public var supportedUsageForRecoveryRole: SupportedUsageForRole? {
		switch self {
		case .device:
			// If a user has lost her phone, how can she use it to perform recovery...she cant!
			return nil

		case .ledgerHQHardwareWallet:
			return .aloneOrWhenCombinedWithOther

		case .offDeviceMnemonic:
			return .aloneOrWhenCombinedWithOther

		case .trustedContact:
			return .aloneOrWhenCombinedWithOther

		case .securityQuestions:
			return .onlyWhenCombinedWithOther
		}
	}

	public var supportedUsageForConfirmationRole: SupportedUsageForRole? {
		switch self {
		case .device:
			return .aloneOrWhenCombinedWithOther

		case .ledgerHQHardwareWallet:
			return .aloneOrWhenCombinedWithOther

		case .offDeviceMnemonic:
			return .aloneOrWhenCombinedWithOther

		case .trustedContact:
			return nil

		case .securityQuestions:
			return .aloneOrWhenCombinedWithOther
		}
	}

	public func supports(
		role: SecurityStructureRole
	) -> Bool {
		supportedUsage(for: role) != nil
	}

	public func supportedUsage(
		for role: SecurityStructureRole
	) -> SupportedUsageForRole? {
		switch role {
		case .primary:
			return supportedUsageForPrimaryRole

		case .recovery:
			return supportedUsageForRecoveryRole

		case .confirmation:
			return supportedUsageForConfirmationRole
		}
	}
}
