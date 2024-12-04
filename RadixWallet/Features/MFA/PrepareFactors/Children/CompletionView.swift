import SwiftUI

// MARK: - Intro.View
extension PrepareFactors {
	struct CompletionView: SwiftUI.View {
		let action: () -> Void

		var body: some SwiftUI.View {
			VStack(spacing: .large2) {
				Image(.securityFactors) // TODO: replace

				Text("Your Factors are Ready")
					.textStyle(.sheetTitle)

				VStack(spacing: .medium3) {
					Text("Now let’s build your Shield.")
						.textStyle(.body1Header)

					Text("Before it’s finished, you’ll have the chance to review it and make any changes.")
						.textStyle(.body1Regular)
				}
				.padding(.horizontal, .medium3)

				Spacer()
			}
			.foregroundStyle(.app.gray1)
			.multilineTextAlignment(.center)
			.padding(.horizontal, .large2)
			.footer {
				Button("Build Shield", action: action)
					.buttonStyle(.primaryRectangular)
			}
		}
	}
}
