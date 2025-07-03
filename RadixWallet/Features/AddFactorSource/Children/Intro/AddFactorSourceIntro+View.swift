import SwiftUI

// MARK: - AddFactorSource.Intro.View
extension AddFactorSource.Intro {
	struct View: SwiftUI.View {
		let store: StoreOf<AddFactorSource.Intro>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				VStack(spacing: .small2) {
					Image(store.kind.icon)
						.resizable()
						.frame(.large)

					Text(store.kind.addFactorTitle)
						.textStyle(.sheetTitle)

					Text(store.kind.addFactorDescription)
						.textStyle(.body1Regular)

					InfoButton(store.kind.infoLinkContent.item, label: store.kind.infoLinkContent.title)
						.padding(.top, .medium1)

					Spacer()
				}
				.foregroundStyle(Color.primaryText)
				.multilineTextAlignment(.center)
				.padding(.horizontal, .large2)
				.footer {
					Button(L10n.Common.continue) {
						store.send(.view(.continueTapped))
					}
					.buttonStyle(.primaryRectangular)
				}
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
			"Add a New Ledger Nano"
		case .offDeviceMnemonic:
			L10n.FactorSources.Card.offDeviceMnemonicTitle
		case .arculusCard:
			"Add a New Arculus Card"
		case .password:
			L10n.FactorSources.Card.passwordTitle
		}
	}

	var addFactorDescription: String {
		switch self {
		case .device:
			L10n.NewBiometricFactor.Intro.subtitle
		case .ledgerHqHardwareWallet:
			"Ledger Nanos are hardware signing devices you can connect to your Radix Wallet with a USB cable and computer."
		case .offDeviceMnemonic:
			L10n.FactorSources.Card.offDeviceMnemonicDescription
		case .arculusCard:
			"Arculus Cards are hardware signing devices you tap to your phone to sign a transaction."
		case .password:
			L10n.FactorSources.Card.passwordDescription
		}
	}

	var nameFactorTitle: String {
		switch self {
		case .device:
			L10n.NewBiometricFactor.Name.title
		case .ledgerHqHardwareWallet:
			"Name your New Ledger Nano"
		case .offDeviceMnemonic:
			L10n.FactorSources.Card.offDeviceMnemonicTitle
		case .arculusCard:
			"Name your New Arculus Card"
		case .password:
			L10n.FactorSources.Card.passwordTitle
		}
	}
}
