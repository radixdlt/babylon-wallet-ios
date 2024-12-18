import SwiftUI

extension PrepareFactorSources {
	struct IntroView: SwiftUI.View {
		let action: () -> Void

		var body: some SwiftUI.View {
			VStack(spacing: .large2) {
				Image(.prepareFactorSourcesIntro)

				Text(L10n.ShieldSetupPrepareFactors.Intro.title)
					.textStyle(.sheetTitle)

				VStack(spacing: .medium3) {
					Text(markdown: L10n.ShieldSetupPrepareFactors.Intro.subtitleTop, emphasizedColor: .app.gray1, emphasizedFont: .app.body1Header)

					Text(L10n.ShieldSetupPrepareFactors.Intro.subtitleBottom)
				}
				.textStyle(.body1Regular)
				.padding(.horizontal, .medium3)

				InfoButton(.buildingshield, label: L10n.InfoLink.Title.buildingshield)

				Spacer()
			}
			.foregroundStyle(.app.gray1)
			.multilineTextAlignment(.center)
			.padding(.horizontal, .large2)
			.footer {
				Button(L10n.ShieldSetupPrepareFactors.Intro.button, action: action)
					.buttonStyle(.primaryRectangular)
			}
		}
	}
}
