extension FactorSourceAccess.State {
	var title: String {
		typealias S = L10n.FactorSourceActions
		switch purpose {
		case .signature:
			return S.Signature.title
		case .createAccount:
			return S.CreateAccount.title
		case .createPersona:
			return S.CreatePersona.title
		case .deriveAccounts:
			return S.DeriveAccounts.title
		case .proveOwnership:
			return S.ProveOwnership.title
		case .encryptMessage:
			return S.EncryptMessage.title
		case .createKey:
			return S.CreateKey.title
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
			}
		case .ledgerHqHardwareWallet:
			switch purpose {
			case .signature:
				return S.Ledger.signMessage
			case .deriveAccounts:
				return S.Ledger.deriveAccountsMessage
			case .createAccount, .createPersona, .proveOwnership, .encryptMessage, .createKey:
				return S.Ledger.message
			}
		default:
			fatalError("Not supported yet")
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
			case .createAccount, .createPersona, .proveOwnership, .encryptMessage, .createKey:
				0.70
			}
		default:
			fatalError("Not supported yet")
		}
	}
}
