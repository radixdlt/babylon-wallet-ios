import SwiftUI

extension NameLedgerFactorSource.State {
	var confirmButtonControlState: ControlState {
		nameIsValid ? .enabled : .disabled
	}
}

// MARK: - NameLedgerFactorSource.View
extension NameLedgerFactorSource {
	@MainActor
	struct View: SwiftUI.View {
		@Perception.Bindable var store: StoreOf<NameLedgerFactorSource>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				NavigationStack {
					ScrollView(showsIndicators: false) {
						VStack(spacing: .zero) {
							Text(L10n.AddLedgerDevice.NameLedger.title)
								.textStyle(.sheetTitle)
								.padding(.top, .small1)
								.padding(.horizontal, .large3)
								.padding(.bottom, .small2)

							Text(L10n.AddLedgerDevice.NameLedger.subtitle)
								.textStyle(.body1Regular)
								.multilineTextAlignment(.center)
								.padding(.horizontal, .large1)
								.padding(.bottom, .large1)

							Text(L10n.AddLedgerDevice.NameLedger.detectedType(store.deviceInfo.model.displayName))
								.textStyle(.body1Header)
								.multilineTextAlignment(.center)
								.padding(.horizontal, .large1)
								.padding(.bottom, .medium1)

							AppTextField(
								placeholder: "",
								text: $store.ledgerName.sending(\.view.ledgerNameChanged),
								hint: .info(L10n.AddLedgerDevice.NameLedger.fieldHint)
							)
							.padding(.horizontal, .medium3)
							.padding(.bottom, .small1)
						}
					}
					.foregroundColor(.primaryText)
					.footer {
						Button(L10n.AddLedgerDevice.NameLedger.continueButtonTitle) {
							store.send(.view(.confirmNameButtonTapped))
						}
						.controlState(store.confirmButtonControlState)
						.buttonStyle(.primaryRectangular)
					}
				}
			}
		}
	}
}

extension P2P.LedgerHardwareWallet.Model {
	var displayName: String {
		switch self {
		case .nanoS:
			"Ledger Nano S"
		case .nanoSPlus:
			"Ledger Nano S+"
		case .nanoX:
			"Ledger Nano X"
		}
	}
}
