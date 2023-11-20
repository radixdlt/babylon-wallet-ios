import ComposableArchitecture
import SwiftUI
extension BaseFactorSourceProtocol {
	var display: String {
		kind.display
	}
}

extension FactorSourceKind {
	var display: String {
		switch self {
		case .device:
			L10n.FactorSources.Kind.device
		case .ledgerHQHardwareWallet:
			L10n.FactorSources.Kind.ledgerHQHardwareWallet
		case .offDeviceMnemonic:
			L10n.FactorSources.Kind.offDeviceMnemonic
		case .trustedContact:
			L10n.FactorSources.Kind.trustedContact
		case .securityQuestions:
			L10n.FactorSources.Kind.securityQuestions
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
			"New phone confirmer"
		case .recovery:
			"Lost phone helper"
		}
	}

	var subtitleSimpleFlow: String {
		switch self {
		case .primary:
			fatalError("not used")
		case .confirmation:
			"Set security questions that are triggered when you move to a new phone"
		case .recovery:
			"Select a third-party who can help you recover your account if you lose your phone."
		}
	}

	var titleAdvancedFlow: String {
		switch self {
		case .primary:
			"To Withdraw Assets"
		case .confirmation:
			"To Confirm Recovery"
		case .recovery:
			"To Initiate Recovery"
		}
	}

	var subtitleAdvancedFlow: String {
		switch self {
		case .primary:
			"Choose which factors allow you to withdraw assets and authenticate yourself to dApps"
		case .confirmation:
			"Chose how you'd like to start the recovery of your accounts in the event of losing your phone."
		case .recovery:
			"Chhose which factors to confirm your account recovery."
		}
	}
}
