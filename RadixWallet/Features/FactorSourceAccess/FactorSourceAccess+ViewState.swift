extension FactorSourceAccess.State {
	var title: String {
		switch purpose {
		case .signature:
			L10n.FactorSourceActions.Signature.title
		case .spotCheck:
			L10n.FactorSourceActions.SpotCheck.title
		case .proveOwnership:
			L10n.FactorSourceActions.ProveOwnership.title
		case .encryptMessage:
			L10n.FactorSourceActions.EncryptMessage.title
		case .updateFactorConfig:
			L10n.FactorSourceActions.UpdatingFactorConfig.title
		case .deriveAccounts:
			L10n.FactorSourceActions.DeriveAccounts.title
		case .createAccountAuthorization:
			L10n.Authorization.CreateAccount.title
		case .createPersonaAuthorization:
			L10n.Authorization.CreatePersona.title
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
				return L10n.Authorization.CreateEntity.message
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
				return L10n.Authorization.CreateEntity.message
			}

		case .arculusCard:
			switch purpose {
			case .signature:
				return S.Arculus.signMessage
			case .spotCheck, .proveOwnership, .encryptMessage:
				return S.Arculus.message
			case .updateFactorConfig, .deriveAccounts, .createAccountAuthorization, .createPersonaAuthorization:
				return S.Arculus.message
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

	var isRetryEnabled: Bool {
		guard let factorSource else {
			return false
		}
		switch factorSource.kind {
		case .device, .ledgerHqHardwareWallet:
			return true
		case .password, .offDeviceMnemonic:
			return false
		case .arculusCard:
			return !self.purpose.requiresSignature
		}
	}

	/// Returns the text to use for the Skip button, nil if is such button shouldn't be visible
	var skipButtonText: String? {
		switch purpose {
		case .signature:
			L10n.FactorSourceActions.useDifferentFactor
		case let .spotCheck(allowSkip):
			allowSkip ? L10n.FactorSourceActions.ignore : nil
		case .proveOwnership, .encryptMessage, .updateFactorConfig, .deriveAccounts, .createAccountAuthorization, .createPersonaAuthorization:
			nil
		}
	}
}
