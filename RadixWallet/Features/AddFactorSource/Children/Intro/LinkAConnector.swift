struct LinkAConnector: View {
	var onContinue: () -> Void

	var body: some View {
		VStack(spacing: .medium3) {
			Image(.linkConnector)
				.padding(.bottom, .large2)

			Text(L10n.LedgerHardwareDevices.LinkConnectorAlert.title)
				.textStyle(.sheetTitle)
				.foregroundStyle(.primaryText)

			Text(L10n.LedgerHardwareDevices.LinkConnectorAlert.message)
				.textStyle(.body1Regular)
				.foregroundStyle(.primaryText)
				.multilineTextAlignment(.center)
				.lineSpacing(.zero)

			Spacer()

			Button(L10n.LedgerHardwareDevices.LinkConnectorAlert.continue) {
				onContinue()
			}
			.buttonStyle(.primaryRectangular)
		}
		.padding()
	}
}
