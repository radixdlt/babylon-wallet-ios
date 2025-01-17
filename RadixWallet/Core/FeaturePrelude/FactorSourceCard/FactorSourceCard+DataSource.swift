// MARK: - FactorSourceCardDataSource
struct FactorSourceCardDataSource {
	let icon: ImageResource
	let title: String
	var subtitle: String?
	var lastUsedOn: Timestamp?
	var messages: [Message] = []
	var linkedEntities: LinkedEntities?
}

// MARK: FactorSourceCardDataSource.Message
extension FactorSourceCardDataSource {
	struct Message: Identifiable, Sendable, Hashable {
		var id: String { text }

		let text: String
		let type: StatusMessageView.ViewType
	}

	struct LinkedEntities: Sendable, Hashable {
		let accounts: [Account]
		let personas: [Persona]
		let hasHiddenEntities: Bool

		var isEmpty: Bool {
			accounts.isEmpty && personas.isEmpty && !hasHiddenEntities
		}
	}
}

extension FactorSourceKind {
	var isSupported: Bool {
		switch self {
		case .device,
		     .ledgerHqHardwareWallet,
		     .offDeviceMnemonic,
		     .arculusCard,
		     .password:
			true
		case .trustedContact, .securityQuestions:
			false
		}
	}

	var icon: ImageResource {
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
			fatalError("Not supported yet")
		}
	}

	var title: String {
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
			fatalError("Not supported yet")
		}
	}

	var details: String {
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
			fatalError("Not supported yet")
		}
	}

	var infoLinkContent: (item: InfoLinkSheet.GlossaryItem, title: String) {
		switch self {
		case .device:
			(.biometricspin, L10n.InfoLink.Title.biometricspin)
		case .ledgerHqHardwareWallet:
			(.ledgernano, L10n.InfoLink.Title.ledgernano)
		case .offDeviceMnemonic:
			(.passphrases, L10n.InfoLink.Title.passphrases)
		case .arculusCard:
			(.arculus, L10n.InfoLink.Title.arculus)
		case .password:
			(.passwords, L10n.InfoLink.Title.passwords)
		default:
			fatalError("Not supported yet")
		}
	}
}
