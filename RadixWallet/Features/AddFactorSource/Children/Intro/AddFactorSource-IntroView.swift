import SwiftUI

// MARK: - AddFactorSource.IntroView
extension AddFactorSource {
	struct IntroView: SwiftUI.View {
		let kind: FactorSourceKind
		let action: () -> Void

		var body: some SwiftUI.View {
			VStack(spacing: .small2) {
				Image(kind.icon)
					.resizable()
					.frame(.large)

				Text(kind.addFactorTitle)
					.textStyle(.sheetTitle)

				Text(kind.addFactorDescription)
					.textStyle(.body1Regular)

//				InfoButton(kind.infoLinkContent.item, label: kind.infoLinkContent.title)
//					.padding(.top, .medium1)

				Spacer()
			}
			.foregroundStyle(.app.gray1)
			.multilineTextAlignment(.center)
			.padding(.horizontal, .large2)
			.footer {
				Button(L10n.Common.continue, action: action)
					.buttonStyle(.primaryRectangular)
			}
		}
	}
}

extension FactorSourceKind {
	var addFactorTitle: String {
		switch self {
		case .device:
			L10n.NewBiometricFactor.Intro.title
		case .ledgerHqHardwareWallet:
			L10n.FactorSources.Card.ledgerTitle
		case .offDeviceMnemonic:
			L10n.FactorSources.Card.offDeviceMnemonicTitle
		case .arculusCard:
			L10n.FactorSources.Card.arculusCardTitle
		case .password:
			L10n.FactorSources.Card.passwordTitle
		}
	}

	var addFactorDescription: String {
		switch self {
		case .device:
			L10n.NewBiometricFactor.Intro.subtitle
		case .ledgerHqHardwareWallet:
			L10n.FactorSources.Card.ledgerDescription
		case .offDeviceMnemonic:
			L10n.FactorSources.Card.offDeviceMnemonicDescription
		case .arculusCard:
			L10n.FactorSources.Card.arculusCardDescription
		case .password:
			L10n.FactorSources.Card.passwordDescription
		}
	}

	var nameFactorTitle: String {
		switch self {
		case .device:
			L10n.NewBiometricFactor.Name.title
		case .ledgerHqHardwareWallet:
			L10n.FactorSources.Card.ledgerTitle
		case .offDeviceMnemonic:
			L10n.FactorSources.Card.offDeviceMnemonicTitle
		case .arculusCard:
			L10n.FactorSources.Card.arculusCardTitle
		case .password:
			L10n.FactorSources.Card.passwordTitle
		}
	}
}
