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

				Text("Success")
					.foregroundColor(.app.gray1)
					.textStyle(.sheetTitle)
					.padding([.top, .horizontal], .medium3)

				Text("Security factor added successfully")
					.foregroundColor(.app.gray1)
					.textStyle(.body1Regular)
					.multilineTextAlignment(.center)
					.padding([.top, .horizontal], .medium3)

				Spacer()
			}
			.footer {
				Button("Close", action: {
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
