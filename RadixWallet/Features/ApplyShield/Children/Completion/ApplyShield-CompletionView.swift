import SwiftUI

extension ApplyShield {
	struct CompletionView: SwiftUI.View {
		let action: () -> Void

		var body: some SwiftUI.View {
			VStack(spacing: .huge2) {
				Image(.shieldSetupOnboardingIntro)
					.resizable()
					.aspectRatio(contentMode: .fit)
					.centered
					.padding(.bottom, .small3)

				VStack(spacing: .medium2) {
					Text(L10n.ShieldWizardApplyShield.ApplyShield.title)
						.textStyle(.sheetTitle)

					Text(L10n.ShieldWizardApplyShield.ApplyShield.subtitle)
						.textStyle(.body1HighImportance)
				}
				.foregroundStyle(.primaryText)
				.multilineTextAlignment(.center)
				.padding(.horizontal, .large2)

				Spacer()
			}
			.background(.primaryBackground)
			.footer {
				Button(L10n.ShieldWizardApplyShield.ApplyShield.saveButton, action: action)
					.buttonStyle(.primaryRectangular)
			}
		}
	}
}
