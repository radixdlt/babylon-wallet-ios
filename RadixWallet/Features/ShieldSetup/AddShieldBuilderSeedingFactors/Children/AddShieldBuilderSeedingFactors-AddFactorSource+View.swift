import SwiftUI

// MARK: - AddShieldBuilderSeedingFactors.SelectFactorSourceToAdd.View
extension AddShieldBuilderSeedingFactors.SelectFactorSourceToAdd {
	struct View: SwiftUI.View {
		let store: StoreOf<AddShieldBuilderSeedingFactors.SelectFactorSourceToAdd>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				ScrollView {
					VStack(spacing: .medium3) {
						Image(.addShieldBuilderSeedingFactorsAdd)

						Text(store.title)
							.textStyle(.sheetTitle)
							.padding(.horizontal, .medium3)

						Text(markdown: store.subtitle, emphasizedColor: .primaryText, emphasizedFont: .app.body1Header)
							.textStyle(.body1Regular)
							.padding(.horizontal, .medium2)

						VStack(spacing: .medium3) {
							ForEachStatic(store.factorSources) { factorSource in
								card(factorSource)
							}

//							if store.showNoHardwareDeviceInfo {
//								InfoButton(.nohardwaredevice, label: L10n.InfoLink.Title.nohardwaredevice)
//									.padding(.vertical, .medium3)
//							}
						}

						Spacer()
					}
					.foregroundStyle(.primaryText)
					.multilineTextAlignment(.center)
					.padding(.horizontal, .medium3)
				}
				.background(.secondaryBackground)
				.footer {
					VStack(spacing: .medium2) {
						Button(store.addButtonTitle) {
							store.send(.view(.addButtonTapped))
						}
						.buttonStyle(.primaryRectangular)
						.controlState(store.controlState)

						Button(L10n.ShieldSetupPrepareFactors.Skip.button) {
							store.send(.view(.skipButtonTapped))
						}
						.buttonStyle(.primaryText())
						.multilineTextAlignment(.center)
					}
				}
			}
		}

		private func card(_ kind: FactorSourceKind) -> some SwiftUI.View {
			WithPerceptionTracking {
				FactorSourceCard(
					kind: .genericDescription(kind),
					mode: .selection(type: .radioButton, selectionEnabled: true, isSelected: store.selected == kind),
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
				[.init(text: L10n.ShieldSetupPrepareFactors.AddAnotherFactor.offDeviceMnemonicHint, type: .warning)]
			default:
				[]
			}
		}
	}
}

private extension AddShieldBuilderSeedingFactors.SelectFactorSourceToAdd.State {
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
			[
				// .password,
				.arculusCard,
				.ledgerHqHardwareWallet,
				.offDeviceMnemonic,
			]
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
