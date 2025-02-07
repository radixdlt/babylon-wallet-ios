import SwiftUI

extension ApplyShield.Intro.State {
	var controlState: ControlState {
		hasEnoughXRD ? .enabled : .disabled
	}
}

// MARK: - ApplyShield.Intro.View
extension ApplyShield.Intro {
	struct View: SwiftUI.View {
		let store: StoreOf<ApplyShield.Intro>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				ScrollView {
					VStack(spacing: .medium3) {
						Image(.applyShieldIntro)

						if let shieldName = store.shieldName {
							Text(L10n.ShieldWizardApplyShield.ShieldCreated.title(shieldName.rawValue))
								.textStyle(.sheetTitle)
						}

						Text(L10n.ShieldWizardApplyShield.ShieldCreated.subtitle)
							.textStyle(.body1Link)
							.padding(.horizontal, .small2)
							.padding(.top, .small3)

						HStack(spacing: .small1) {
							Image(.info)
								.resizable()
								.frame(.smallest)
							Text(L10n.ShieldWizardApplyShield.ShieldCreated.note)
								.textStyle(.body2HighImportance)
								.multilineTextAlignment(.leading)
								.flushedLeft
						}
						.foregroundStyle(.app.gray1)
						.embedInContainer
						.padding(.top, .small1)

						if !store.hasEnoughXRD {
							StatusMessageView(
								text: L10n.ShieldWizardApplyShield.ShieldCreated.notEnoughXrd,
								type: .warning,
								useNarrowSpacing: true,
								useSmallerFontSize: true
							)
							.padding(.horizontal, .medium3)
							.padding(.top, .small2)
						}

						Spacer()
					}
					.foregroundStyle(.app.gray1)
					.multilineTextAlignment(.center)
					.padding([.horizontal, .bottom], .large2)
				}
				.footer {
					VStack(spacing: .medium2) {
						Button(L10n.ShieldWizardApplyShield.ShieldCreated.applyButton) {
							self.store.send(.view(.startApplyingButtonTapped))
						}
						.buttonStyle(.primaryRectangular)
						.controlState(store.controlState)

						Button(L10n.ShieldWizardApplyShield.ShieldCreated.skipButton) {
							store.send(.view(.skipButtonTapped))
						}
						.buttonStyle(.primaryText())
						.multilineTextAlignment(.center)
					}
				}
				.task {
					store.send(.view(.task))
				}
			}
		}
	}
}
