import SwiftUI

public struct AccountDeletedView: View {
	public let onGoHome: () -> Void

	public var body: some View {
		ScrollView {
			VStack(spacing: .medium2) {
				Image(.deleteAccount)
					.resizable()
					.frame(.medium)

				Text("Account Deleted")
					.textStyle(.sheetTitle)
					.foregroundColor(.app.gray1)

				Text("Your Account has been permanently deleted. Your wallet settings have been updated.")
					.textStyle(.body1Regular)
					.foregroundColor(.app.gray1)

				Spacer()
			}
			.multilineTextAlignment(.center)
			.padding(.horizontal, .large2)
			.padding(.top, .huge1)
		}
		.footer {
			Button("Go to Homescreen", action: onGoHome)
				.buttonStyle(.primaryRectangular)
		}
	}
}
