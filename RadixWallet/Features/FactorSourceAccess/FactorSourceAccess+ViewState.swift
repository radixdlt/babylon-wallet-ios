extension FactorSourceAccess.State {
	var title: String {
		switch purpose {
		case .signature:
			S.Signature.title
		case .spotCheck:
			"Check Factor"
		case .proveOwnership:
			L10n.FactorSourceActions.ProveOwnership.title
		case .encryptMessage:
			S.EncryptMessage.title
		case .updateFactorConfig:
			S.UpdatingFactorConfig.title
		case .deriveAccounts:
			S.DeriveAccounts.title
		case .createAccountAuthorization:
			S.CreateAccount.title
		case .createPersonaAuthorization:
			S.CreatePersona.title
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
}
