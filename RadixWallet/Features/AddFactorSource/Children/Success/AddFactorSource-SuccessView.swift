extension AddFactorSource {
	struct CompletionView: View {
		@Environment(\.dismiss) var dismiss

		var body: some View {
			VStack(spacing: .zero) {
				CloseButton {
					dismiss()
				}
				.flushedLeft
				.padding([.top, .horizontal], .medium3)

				Spacer()

				Image(asset: AssetResource.successCheckmark)

				Text(L10n.NewFactor.Success.title)
					.foregroundColor(.primaryText)
					.textStyle(.sheetTitle)
					.padding([.top, .horizontal], .medium3)

				Text(L10n.NewFactor.Success.subtitle)
					.foregroundColor(.primaryText)
					.textStyle(.body1Regular)
					.multilineTextAlignment(.center)
					.padding([.top, .horizontal], .medium3)

				Spacer()
			}
			.background(Color.primaryBackground)
			.footer {
				Button(L10n.Common.close, action: {
					dismiss()
				})
				.buttonStyle(.primaryRectangular)
			}
			.presentationDragIndicator(.visible)
			.presentationDetents([.medium])
			.presentationBackground(.blur)
		}
	}
}
