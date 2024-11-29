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
			L10n.FactorSources.Card.deviceTitle
		case .ledgerHqHardwareWallet:
			L10n.FactorSources.Card.ledgerTitle
		case .offDeviceMnemonic:
			L10n.FactorSources.Card.passphraseTitle
		case .arculusCard:
			L10n.FactorSources.Card.arculusCardTitle
		case .password:
			L10n.FactorSources.Card.passwordTitle
		case .trustedContact, .securityQuestions:
			nil
		}
	}

	var details: String? {
		switch self {
		case .device:
			L10n.FactorSources.Card.deviceDescription
		case .ledgerHqHardwareWallet:
			L10n.FactorSources.Card.ledgerDescription
		case .offDeviceMnemonic:
			L10n.FactorSources.Card.passphraseDescription
		case .arculusCard:
			L10n.FactorSources.Card.arculusCardDescription
		case .password:
			L10n.FactorSources.Card.passwordDescription
		case .trustedContact, .securityQuestions:
			nil
		}
	}
}
