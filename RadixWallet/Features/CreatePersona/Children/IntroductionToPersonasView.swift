import SwiftUI

public struct IntroductionToPersonasView: View {
	public let onContinue: () -> Void

	public var body: some View {
		ScrollView {
			VStack(spacing: .large2) {
				Image(.persona)
					.resizable()
					.frame(.veryHuge)

				Text(L10n.CreatePersona.Introduction.title)
					.foregroundColor(.primaryText)
					.textStyle(.sheetTitle)

				InfoButton(.personas, label: L10n.InfoLink.Title.personasLearnAbout)

				Text(L10n.CreatePersona.Introduction.subtitle1)
					.font(.app.body1Regular)
					.foregroundColor(.primaryText)

				Text(L10n.CreatePersona.Introduction.subtitle2)
					.font(.app.body1Regular)
					.foregroundColor(.primaryText)
			}
			.multilineTextAlignment(.center)
			.padding(.horizontal, .large2)
			.padding(.bottom, .medium2)
		}
		.background(.primaryBackground)
		.footer {
			Button(L10n.CreatePersona.Introduction.continue, action: onContinue)
				.buttonStyle(.primaryRectangular)
		}
	}
}
