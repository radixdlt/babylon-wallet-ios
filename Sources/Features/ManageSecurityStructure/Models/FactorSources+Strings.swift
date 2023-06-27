import FeaturePrelude

extension BaseFactorSourceProtocol {
	var display: String {
		kind.display
	}
}

extension FactorSourceKind {
	var display: String {
		switch self {
		// FIXME: Strings
		case .device:
			return "Phone"
		case .ledgerHQHardwareWallet:
			return "Ledger"
		case .offDeviceMnemonic:
			return "Seed phrase"
		case .trustedContact:
			return "Third-party"
		case .securityQuestions:
			return "Security Questions"
		}
	}
}

extension RoleProtocol {
	static var titleSimpleFlow: String {
		role.titleSimpleFlow
	}

	static var subtitleSimpleFlow: String {
		role.subtitleSimpleFlow
	}

	static var titleAdvancedFlow: String {
		role.titleAdvancedFlow
	}

	static var subtitleAdvancedFlow: String {
		role.subtitleAdvancedFlow
	}
}

extension SecurityStructureRole {
	var titleSimpleFlow: String {
		switch self {
		case .primary:
			fatalError("not used")
		case .confirmation:
			return "New phone confirmer"
		case .recovery:
			return "Lost phone helper"
		}
	}

	var subtitleSimpleFlow: String {
		switch self {
		case .primary:
			fatalError("not used")
		case .confirmation:
			return "Set security questions that are trigger when you move to a new phone"
		case .recovery:
			return "Select a third-party who can help you recover your account if you lose your phone."
		}
	}

	var titleAdvancedFlow: String {
		switch self {
		case .primary:
			return "To Withdraw Assets"
		case .confirmation:
			return "To Confirm Recovery"
		case .recovery:
			return "To Initiate Recovery"
		}
	}

	var subtitleAdvancedFlow: String {
		switch self {
		case .primary:
			return "Choose which factors allow you to withdraw assets and authenticate yourself to dApps"
		case .confirmation:
			return "Chose how you'd like to start the recovery of your accounts in the event of losing your phone."
		case .recovery:
			return "Chhose which factors to confirm your account recovery."
		}
	}
}
