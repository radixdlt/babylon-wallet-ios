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
		case .passphrase:
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
		case .passphrase:
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
		case .passphrase:
			"Enter a decentralized password to approve"
		case .trustedContact, .securityQuestions:
			nil
		}
	}
}

// TODO: move to Sargon
extension FactorSource {
	var name: String? {
		switch self {
		case let .device(factorSource):
			factorSource.hint.name
		case let .ledger(factorSource):
			factorSource.hint.name
		case let .offDeviceMnemonic(factorSource):
			factorSource.hint.displayName.value
		case let .arculusCard(factorSource):
			factorSource.hint.name
		case let .trustedContact(factorSource):
			factorSource.contact.name.value
		case .securityQuestions, .passphrase:
			nil
		}
	}
}
