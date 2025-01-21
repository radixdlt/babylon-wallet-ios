
// MARK: - ViewState
extension FactorSourceAccess.State {
	var viewState: FactorSourceAccess.ViewState {
		.init(
			title: title,
			message: message,
			externalDevice: externalDevice,
			isRetryEnabled: isRetryEnabled,
			height: height
		)
	}

	private var title: String {
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

	private var message: String {
		typealias S = L10n.FactorSourceActions
		switch kind {
		case .device:
			switch purpose {
			case .signature:
				return S.Device.signMessage
			case .createAccount, .createPersona, .deriveAccounts, .proveOwnership, .encryptMessage, .createKey:
				return S.Device.message
			}
		case .ledger:
			switch purpose {
			case .signature:
				return S.Ledger.signMessage
			case .deriveAccounts:
				return S.Ledger.deriveAccountsMessage
			case .createAccount, .createPersona, .proveOwnership, .encryptMessage, .createKey:
				return S.Ledger.message
			}
		}
	}

	private var externalDevice: String? {
		switch kind {
		case .device:
			nil
		case let .ledger(value):
			value?.hint.label
		}
	}

	private var isRetryEnabled: Bool {
		switch kind {
		case .device:
			false
		case .ledger:
			true
		}
	}

	private var height: CGFloat {
		switch kind {
		case .device:
			0.55
		case .ledger:
			switch purpose {
			case .signature, .deriveAccounts:
				0.74
			case .createAccount, .createPersona, .proveOwnership, .encryptMessage, .createKey:
				0.70
			}
		}
	}
}
