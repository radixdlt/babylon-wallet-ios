import EngineToolkit

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
			.aloneOrWhenCombinedWithOther

		case .ledgerHQHardwareWallet:
			.aloneOrWhenCombinedWithOther

		case .offDeviceMnemonic:
			.aloneOrWhenCombinedWithOther

		case .trustedContact:
			nil

		case .securityQuestions:
			.onlyWhenCombinedWithOther
		}
	}

	public var supportedUsageForRecoveryRole: SupportedUsageForRole? {
		switch self {
		case .device:
			// If a user has lost her phone, how can she use it to perform recovery...she cant!
			nil

		case .ledgerHQHardwareWallet:
			.aloneOrWhenCombinedWithOther

		case .offDeviceMnemonic:
			.aloneOrWhenCombinedWithOther

		case .trustedContact:
			.aloneOrWhenCombinedWithOther

		case .securityQuestions:
			.onlyWhenCombinedWithOther
		}
	}

	public var supportedUsageForConfirmationRole: SupportedUsageForRole? {
		switch self {
		case .device:
			.aloneOrWhenCombinedWithOther

		case .ledgerHQHardwareWallet:
			.aloneOrWhenCombinedWithOther

		case .offDeviceMnemonic:
			.aloneOrWhenCombinedWithOther

		case .trustedContact:
			nil

		case .securityQuestions:
			.aloneOrWhenCombinedWithOther
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
			supportedUsageForPrimaryRole

		case .recovery:
			supportedUsageForRecoveryRole

		case .confirmation:
			supportedUsageForConfirmationRole
		}
	}
}
