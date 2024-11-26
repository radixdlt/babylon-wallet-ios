import Sargon
import SwiftUI

// MARK: - FactorSourceCard
struct FactorSourceCard: View {
	private let mode: Mode
	private let dataSource: FactorSourceCardDataSource

	var onRemoveTapped: (() -> Void)? = nil

	var body: some View {
		switch mode {
		case .display, .selection:
			card
		case .removal:
			HStack {
				card

				Button {
					onRemoveTapped?()
				} label: {
					Image(asset: AssetResource.close)
						.frame(.smallest)
				}
				.foregroundColor(.app.gray2)
			}
		}
	}

	private var card: some View {
		VStack(spacing: 0) {
			topCard
				.padding(.horizontal, .medium3)
				.padding(.vertical, .medium2)

			if dataSource.hasAccountsOrPersonas {}
		}
		.background(.app.white)
		.roundedCorners(radius: .small1)
		.cardShadow
	}

	private var topCard: some View {
		HStack(spacing: .medium3) {
			Image(dataSource.icon)

			VStack(alignment: .leading, spacing: .small3) {
				Text(dataSource.title)
					.textStyle(.body1Header)
					.foregroundStyle(.app.gray1)

				if let subtitle = dataSource.subtitle {
					Text(subtitle)
						.textStyle(.body2Regular)
						.foregroundStyle(.app.gray2)
				}

				if let lastUsedOn = dataSource.lastUsedOn {
					Text(
						markdown: "**Last Used:** \(lastUsedOn.formatted())",
						emphasizedColor: .app.gray2,
						emphasizedFont: .app.body2Link
					)
					.textStyle(.body2Regular)
					.foregroundStyle(.app.gray2)
				}
			}
            .flushedLeft

			if case let .selection(type, isSelected) = mode {
				switch type {
				case .radioButton:
					RadioButton(
						appearance: .dark,
						state: isSelected ? .selected : .unselected
					)
				case .checkmark:
					CheckmarkView(appearance: .dark, isChecked: isSelected)
				}
			}
		}
	}
}

extension FactorSourceCard {
	enum Mode {
		case display
		case selection(type: SelectionType, isSelected: Bool)
		case removal
	}

	enum SelectionType {
		case radioButton
		case checkmark
	}
}

// MARK: - FactorSourceCardDataSource
struct FactorSourceCardDataSource {
	let icon: ImageResource
	let title: String
	var subtitle: String?
	var lastUsedOn: Timestamp?
	var accounts: Accounts = []
	var personas: Personas = []

	var hasAccountsOrPersonas: Bool {
		!accounts.isEmpty || !personas.isEmpty
	}
}

extension FactorSourceCard {
	static func kind(_ kind: FactorSourceKind, mode: Mode) -> Self? {
		guard
			let icon = kind.icon,
			let title = kind.title,
			let details = kind.details
		else { return nil }

		return Self(
			mode: mode,
			dataSource: .init(
				icon: icon,
				title: title,
				subtitle: details
			)
		)
	}

	static func instanceCompact(factorSource: FactorSource, mode: Mode) -> Self? {
		guard
			let icon = factorSource.factorSourceKind.icon,
			let name = factorSource.name
		else { return nil }

		return Self(
			mode: mode,
			dataSource: .init(
				icon: icon,
				title: name
			)
		)
	}

	static func instanceRegular(factorSource: FactorSource, mode: Mode) -> Self? {
		guard
			let icon = factorSource.factorSourceKind.icon,
			let name = factorSource.name,
			let details = factorSource.factorSourceKind.details
		else { return nil }

		return Self(
			mode: mode,
			dataSource: .init(
				icon: icon,
				title: name,
				subtitle: details
			)
		)
	}

	static func instanceLastUsed(
		factorSource: FactorSource,
		mode: Mode,
		accounts: Accounts = [],
		personas: Personas = []
	) -> Self? {
		guard
			let icon = factorSource.factorSourceKind.icon,
			let name = factorSource.name
		else { return nil }

		return Self(
			mode: mode,
			dataSource: .init(
				icon: icon,
				title: name,
				lastUsedOn: factorSource.common.lastUsedOn,
				accounts: accounts,
				personas: personas
			)
		)
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
