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
					Text("Apply your Shield")
						.textStyle(.sheetTitle)

					Text("Now let’s save your Shield settings to your wallet and apply them on the Radix Network with a transaction.")
						.textStyle(.body1HighImportance)
				}
				.foregroundStyle(.app.gray1)
				.multilineTextAlignment(.center)
				.padding(.horizontal, .large2)

				Spacer()
			}
			.footer {
				Button("Save and Apply", action: action)
					.buttonStyle(.primaryRectangular)
			}
		}
	}
}
