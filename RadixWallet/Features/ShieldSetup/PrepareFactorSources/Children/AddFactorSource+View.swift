import SwiftUI

// MARK: - PrepareFactorSources.AddFactorSource.View
extension PrepareFactorSources.AddFactorSource {
	struct View: SwiftUI.View {
		let store: StoreOf<PrepareFactorSources.AddFactorSource>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				ScrollView {
					VStack(spacing: .large2) {
						Image(.prepareFactorSourcesAdd)

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

							if store.showNoHardwareDeviceInfo {
								InfoButton(.nohardwaredevice, label: "I don’t have a hardware device") // TODO: localization
									.padding(.vertical, .medium3)
							}
						}

						Spacer()
					}
					.foregroundStyle(.app.gray1)
					.multilineTextAlignment(.center)
					.padding(.horizontal, .medium3)
				}
				.footer {
					VStack(spacing: .medium2) {
						Button(store.addButtonTitle) {
							store.send(.view(.addButtonTapped))
						}
						.buttonStyle(.primaryRectangular)
						.controlState(store.controlState)

						// TODO: localization
						Button("Skip and create an empty shield") {
							store.send(.view(.skipButtonTapped))
						}
						.buttonStyle(.primaryText())
					}
				}
			}
		}

		private func card(_ kind: FactorSourceKind) -> some SwiftUI.View {
			WithPerceptionTracking {
				FactorSourceCard(
					kind: .genericDescription(kind),
					mode: .selection(type: .radioButton, isSelected: store.selected == kind),
					messages: self.messages(for: kind)
				)
				.onTapGesture {
					store.send(.view(.selected(kind)))
				}
			}
		}

		private func messages(for kind: FactorSourceKind) -> [FactorSourceCardDataSource.Message] {
			switch (kind, store.selected) {
			case (.offDeviceMnemonic, .offDeviceMnemonic):
				[.init(text: L10n.ShieldSetupPrepareFactors.AddAnotherFactor.passphraseHint, type: .warning)]
			default:
				[]
			}
		}
	}
}

private extension PrepareFactorSources.AddFactorSource.State {
	var title: String {
		switch mode {
		case .hardware:
			L10n.ShieldSetupPrepareFactors.AddHardwareFactor.title
		case .any:
			L10n.ShieldSetupPrepareFactors.AddAnotherFactor.title
		}
	}

	var subtitle: String {
		switch mode {
		case .hardware:
			L10n.ShieldSetupPrepareFactors.AddHardwareFactor.subtitle
		case .any:
			L10n.ShieldSetupPrepareFactors.AddAnotherFactor.subtitle
		}
	}

	var factorSources: [FactorSourceKind] {
		switch mode {
		case .hardware:
			[.arculusCard, .ledgerHqHardwareWallet]
		case .any:
			[.password, .arculusCard, .ledgerHqHardwareWallet, .offDeviceMnemonic]
		}
	}

	var addButtonTitle: String {
		switch mode {
		case .hardware:
			L10n.ShieldSetupPrepareFactors.AddHardwareFactor.button
		case .any:
			L10n.ShieldSetupPrepareFactors.AddAnotherFactor.button
		}
	}

	var showNoHardwareDeviceInfo: Bool {
		switch mode {
		case .hardware:
			true
		case .any:
			false
		}
	}

	var controlState: ControlState {
		selected == nil ? .disabled : .enabled
	}
}
