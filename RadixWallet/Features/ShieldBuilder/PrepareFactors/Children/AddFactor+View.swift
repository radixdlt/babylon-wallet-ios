import SwiftUI

// MARK: - PrepareFactors.AddFactor.View
extension PrepareFactors.AddFactor {
	struct View: SwiftUI.View {
		let store: StoreOf<PrepareFactors.AddFactor>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				ScrollView {
					VStack(spacing: .large2) {
						Image(.prepareFactorsAdd)

						Text(store.title)
							.textStyle(.sheetTitle)
							.padding(.horizontal, .medium3)

						Text(markdown: store.subtitle, emphasizedColor: .app.gray1, emphasizedFont: .app.body1Header)
							.textStyle(.body1Regular)
							.padding(.horizontal, .medium2)

						VStack(spacing: .medium3) {
							ForEachStatic(store.factorSources) { factorSource in
								card(factorSource)
							}
						}

						Spacer()
					}
					.foregroundStyle(.app.gray1)
					.multilineTextAlignment(.center)
					.padding(.horizontal, .medium3)
				}
				.footer {
					VStack(spacing: .small2) {
						Button(store.primaryButton) {
							store.send(.view(.addButtonTapped))
						}
						.buttonStyle(.primaryRectangular)
						.controlState(store.controlState)

						if let text = store.secondaryButton {
							Button(text) {
								store.send(.view(.noDeviceButtonTapped))
							}
							.buttonStyle(.alternativeRectangular)
						}
					}
				}
			}
		}

		private func card(_ kind: FactorSourceKind) -> some SwiftUI.View {
			FactorSourceCard(
				kind: .genericDescription(kind),
				mode: .selection(type: .radioButton, isSelected: store.selected == kind),
				messages: self.messages(for: kind)
			)
			.onTapGesture {
				store.send(.view(.selected(kind)))
			}
		}

		private func messages(for kind: FactorSourceKind) -> [FactorSourceCardDataSource.Message] {
			switch (kind, store.selected) {
			case (.offDeviceMnemonic, .offDeviceMnemonic):
				[.init(text: "Choosing a passphrase is only recommended for advanced users", type: .warning)]
			default:
				[]
			}
		}
	}
}

private extension PrepareFactors.AddFactor.State {
	var title: String {
		switch mode {
		case .hardwareOnly:
			"Add a Hardware Device"
		case .any:
			"Add Another Factor"
		}
	}

	var subtitle: String {
		switch mode {
		case .hardwareOnly:
			"Choose a hardware device to use as a security factor in your Shield."
		case .any:
			"You need to add **1 more factor** to begin building your Shield."
		}
	}

	var factorSources: [FactorSourceKind] {
		switch mode {
		case .hardwareOnly:
			[.arculusCard, .ledgerHqHardwareWallet]
		case .any:
			[.password, .arculusCard, .ledgerHqHardwareWallet, .offDeviceMnemonic]
		}
	}

	var primaryButton: String {
		switch mode {
		case .hardwareOnly:
			"Add Hardware Device"
		case .any:
			"Add Factor"
		}
	}

	var secondaryButton: String? {
		switch mode {
		case .hardwareOnly:
			"I don’t have a hardware device"
		case .any:
			nil
		}
	}

	var controlState: ControlState {
		selected == nil ? .disabled : .enabled
	}
}
