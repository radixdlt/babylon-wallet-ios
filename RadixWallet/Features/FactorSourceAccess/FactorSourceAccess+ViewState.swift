
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
