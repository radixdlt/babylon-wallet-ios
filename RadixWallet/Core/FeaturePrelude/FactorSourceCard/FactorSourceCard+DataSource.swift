// MARK: - FactorSourceCardDataSource
struct FactorSourceCardDataSource {
	let icon: ImageResource
	let title: String
	var subtitle: String?
	var lastUsedOn: Timestamp?
	var messages: [Message] = []
	var accounts: [Account] = []
	var personas: [Persona] = []

	var hasAccountsOrPersonas: Bool {
		!accounts.isEmpty || !personas.isEmpty
	}
}

// MARK: FactorSourceCardDataSource.Message
extension FactorSourceCardDataSource {
	struct Message: Identifiable {
		var id: String { text }

		let text: String
		let type: StatusMessageView.ViewType
	}
}

extension FactorSourceKind {
	var icon: ImageResource? {
		switch self {
		case .device:
			.deviceFactor
		case .ledgerHqHardwareWallet:
			.ledgerFactor
		case .offDeviceMnemonic:
			.passphraseFactor
		case .arculusCard:
			.arculusFactor
		case .password:
			.passwordFactor
		case .trustedContact, .securityQuestions:
			nil
		}
	}

	var title: String? {
		switch self {
		case .device:
			"Biometrics/PIN"
		case .ledgerHqHardwareWallet:
			"Ledger Nano"
		case .offDeviceMnemonic:
			"Passphrase"
		case .arculusCard:
			"Arculus Card"
		case .password:
			"Password"
		case .trustedContact, .securityQuestions:
			nil
		}
	}

	var details: String? {
		switch self {
		case .device:
			"Use phone biometrics/PIN to approve"
		case .ledgerHqHardwareWallet:
			"Connect via USB to approve"
		case .offDeviceMnemonic:
			"Enter a seed phrase to approve"
		case .arculusCard:
			"Tap to your phone to approve"
		case .password:
			"Enter a decentralized password to approve"
		case .trustedContact, .securityQuestions:
			nil
		}
	}
}
