
// MARK: - ViewState
extension FactorSourceAccess.State {
	var viewState: FactorSourceAccess.ViewState {
		.init(
			title: title,
			message: message,
			externalDevice: externalDevice,
			retryEnabled: retryEnabled
		)
	}

	private var title: String {
		typealias S = L10n.FactorSourceAccess.Title
		switch purpose {
		case .signature:
			return S.signature
		case .createAccount:
			return S.createAccount
		case .deriveAccounts:
			return S.deriveAccounts
		case .proveOwnership:
			return S.proveOwnership
		case .encryptMessage:
			return S.encryptMessage
		case .createKey:
			return S.createKey
		}
	}

	private var message: String {
		typealias S = L10n.FactorSourceAccess.Message
		switch kind {
		case .device:
			switch purpose {
			case .signature:
				return S.Device.signature
			case .createAccount, .deriveAccounts, .proveOwnership, .encryptMessage, .createKey:
				return S.Device.general
			}
		case .ledger:
			switch purpose {
			case .signature:
				return S.Ledger.signature
			case .deriveAccounts:
				return S.Ledger.deriveAccounts
			case .createAccount, .proveOwnership, .encryptMessage, .createKey:
				return S.Ledger.general
			}
		}
	}

	private var externalDevice: String? {
		switch kind {
		case .device:
			nil
		case let .ledger(value):
			value?.hint.name
		}
	}

	private var retryEnabled: Bool {
		switch kind {
		case .device:
			false
		case .ledger:
			true
		}
	}
}
