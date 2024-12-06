import SwiftUI

extension PrepareFactorSources {
	struct CompletionView: SwiftUI.View {
		let action: () -> Void

		var body: some SwiftUI.View {
			VStack(spacing: .large2) {
				Image(.prepareFactorSourcesCompletion)

				Text(L10n.ShieldSetupPrepareFactors.Completion.title)
					.textStyle(.sheetTitle)

				VStack(spacing: .medium3) {
					Text(L10n.ShieldSetupPrepareFactors.Completion.subtitleTop)
						.textStyle(.body1Header)

					Text(L10n.ShieldSetupPrepareFactors.Completion.subtitleBottom)
						.textStyle(.body1Regular)
				}
				.padding(.horizontal, .medium3)

				Spacer()
			}
			.foregroundStyle(.app.gray1)
			.multilineTextAlignment(.center)
			.padding(.horizontal, .large2)
			.footer {
				Button(L10n.ShieldSetupPrepareFactors.Completion.button, action: action)
					.buttonStyle(.primaryRectangular)
			}
		}
	}
}
