extension FactorSourceAccess.State {
	var title: String {
		typealias S = L10n.FactorSourceActions
		switch purpose {
		case .signature:
			return S.Signature.title
		case .spotCheck:
			return "Check Factor"
		case .proveOwnership:
			return S.ProveOwnership.title
		case .encryptMessage:
			return S.EncryptMessage.title
		case .updateFactorConfig:
			return S.UpdatingFactorConfig.title
		case .deriveAccounts:
			return S.DeriveAccounts.title
		case .createAccountAuthorization:
			return S.CreateAccount.title
		case .createPersonaAuthorization:
			return S.CreatePersona.title
		}
	}

	var message: String {
		typealias S = L10n.FactorSourceActions
		switch kind {
		case .device:
			switch purpose {
			case .signature:
				return S.Device.signMessage
			case .spotCheck, .proveOwnership, .encryptMessage, .updateFactorConfig, .deriveAccounts:
				return S.Device.message
			case .createAccountAuthorization, .createPersonaAuthorization:
				return "Use your phone’s biometrics or PIN to confirm you want to do this."
			}

		case .ledgerHqHardwareWallet:
			switch purpose {
			case .signature:
				return S.Ledger.signMessage
			case .spotCheck, .proveOwnership, .encryptMessage:
				return S.Ledger.message
			case .updateFactorConfig, .deriveAccounts:
				return S.Ledger.deriveKeysMessage
			case .createAccountAuthorization, .createPersonaAuthorization:
				fatalError("Not supported")
			}

		case .arculusCard:
			switch purpose {
			case .signature:
				return S.Arculus.signMessage
			case .spotCheck, .proveOwnership, .encryptMessage:
				return S.Arculus.message
			case .updateFactorConfig, .deriveAccounts:
				return S.Arculus.deriveKeysMessage
			case .createAccountAuthorization, .createPersonaAuthorization:
				fatalError("Not supported")
			}

		case .password:
			switch purpose {
			case .signature:
				return S.Password.signMessage
			case .spotCheck, .proveOwnership, .encryptMessage, .updateFactorConfig, .deriveAccounts:
				return S.Password.message
			case .createAccountAuthorization, .createPersonaAuthorization:
				fatalError("Not supported")
			}

		case .offDeviceMnemonic:
			switch purpose {
			case .signature:
				return S.OffDeviceMnemonic.signMessage
			case .spotCheck, .proveOwnership, .encryptMessage, .updateFactorConfig, .deriveAccounts:
				return S.OffDeviceMnemonic.message
			case .createAccountAuthorization, .createPersonaAuthorization:
				fatalError("Not supported")
			}

		default:
			fatalError("Not supported yet")
		}
	}

	var showCard: Bool {
		switch purpose {
		case .signature, .spotCheck, .proveOwnership, .encryptMessage, .updateFactorConfig, .deriveAccounts:
			true
		case .createAccountAuthorization, .createPersonaAuthorization:
			false
		}
	}

	var isRetryEnabled: Bool {
		guard let factorSource else {
			return false
		}
		switch factorSource.kind {
		case .device, .ledgerHqHardwareWallet, .arculusCard:
			return true
		case .password, .offDeviceMnemonic:
			return false
		case .trustedContact, .securityQuestions:
			fatalError("Not supported yet")
		}
	}

	var isSkipEnabled: Bool {
		switch purpose {
		case .signature:
			true
		case .spotCheck, .proveOwnership, .encryptMessage, .updateFactorConfig, .deriveAccounts, .createAccountAuthorization, .createPersonaAuthorization:
			false
		}
	}

	var height: CGFloat {
		0.74
	}
}
