extension FactorSourceAccess.State {
	var title: String {
		switch purpose {
		case .signature:
			L10n.FactorSourceActions.Signature.title
		case .createAccount:
			L10n.Authorization.CreateAccount.title
		case .createPersona:
			L10n.Authorization.CreatePersona.title
		case .deriveAccounts:
			L10n.FactorSourceActions.DeriveAccounts.title
		case .proveOwnership:
			L10n.FactorSourceActions.ProveOwnership.title
		case .encryptMessage:
			L10n.FactorSourceActions.EncryptMessage.title
		case .createKey:
			L10n.FactorSourceActions.CreateKey.title
		case let .authorization(authorization):
			switch authorization {
			case .creatingAccount, .creatingAccounts:
				L10n.Authorization.CreateAccount.title
			case .creatingPersona, .creatingPersonas:
				L10n.Authorization.CreatePersona.title
			}
		}
	}

	var message: String {
		typealias S = L10n.FactorSourceActions
		switch kind {
		case .device:
			switch purpose {
			case .signature:
				return S.Device.signMessage
			case .createAccount, .createPersona, .deriveAccounts, .proveOwnership, .encryptMessage, .createKey:
				return S.Device.message
			case .authorization:
				return "Use your phone’s biometrics or PIN to confirm you want to do this."
			}
		case .ledgerHqHardwareWallet:
			switch purpose {
			case .signature:
				return S.Ledger.signMessage
			case .deriveAccounts:
				return S.Ledger.deriveAccountsMessage
			case .createAccount, .createPersona, .proveOwnership, .encryptMessage, .createKey:
				return S.Ledger.message
			case .authorization:
				return "Use your phone’s biometrics or PIN to confirm you want to do this."
			}
		default:
			fatalError("Not supported yet")
		}
	}

	var showDescription: Bool {
		switch purpose {
		case .authorization:
			false
		default:
			true
		}
	}

	var label: String? {
		switch factorSource {
		case .none:
			nil
		case let .device(device):
			device.hint.label
		case let .ledger(ledger):
			ledger.hint.label
		default:
			fatalError("Not supported yet")
		}
	}

	var isRetryEnabled: Bool {
		guard factorSource != nil else {
			return false
		}
		switch kind {
		case .device:
			return true
		case .ledgerHqHardwareWallet:
			return true
		default:
			fatalError("Not supported yet")
		}
	}

	var height: CGFloat {
		switch kind {
		case .device:
			0.55
		case .ledgerHqHardwareWallet:
			switch purpose {
			case .signature, .deriveAccounts:
				0.74
			case .createAccount, .createPersona, .proveOwnership, .encryptMessage, .createKey, .authorization:
				0.70
			}
		default:
			fatalError("Not supported yet")
		}
	}
}
