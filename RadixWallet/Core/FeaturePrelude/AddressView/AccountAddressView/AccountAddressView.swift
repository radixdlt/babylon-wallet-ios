import SwiftUI

struct AccountAddressView: View {
	@Dependency(\.dismiss) var dismiss

	var body: some View {
		VStack(spacing: .medium3) {
			top
		}
		.withNavigationBar {
			Task {
				await dismiss()
			}
		}
		.presentationDetents([.large])
		.presentationDragIndicator(.visible)
		.onFirstTask {}
	}

	private var top: some View {
		VStack(spacing: .small2) {
			Text("My Main Account")
				.textStyle(.sheetTitle)
				.foregroundColor(.app.gray1)

			Text("Address QR Code")
				.textStyle(.secondaryHeader)
				.foregroundColor(.app.gray1)
		}
	}
}
