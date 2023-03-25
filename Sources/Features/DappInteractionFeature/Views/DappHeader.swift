import FeaturePrelude

struct DappHeader: View {
	let icon: ImageAsset?
	let title: String
	let subtitle: AttributedString

	var body: some View {
		VStack(spacing: .medium2) {
			// NOTE: using placeholder until API is available
			Color.app.gray4
				.frame(.medium)
				.cornerRadius(.medium3)

			Text(title)
				.foregroundColor(.app.gray1)
				.lineSpacing(0)
				.textStyle(.sheetTitle)

			Text(subtitle)
				.textStyle(.secondaryHeader)
		}
		.multilineTextAlignment(.center)
		.padding(.bottom, .medium2)
	}
}
