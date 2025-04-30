import SwiftUI

public struct AccountDeletedView: View {
	public let onGoHome: () -> Void

	public var body: some View {
		ScrollView {
			VStack(spacing: .medium2) {
				Image(.deleteAccount)
					.resizable()
					.frame(.medium)

				Text(L10n.AccountSettings.AccountDeleted.title)
					.textStyle(.sheetTitle)
					.foregroundColor(.primaryText)

				Text(L10n.AccountSettings.AccountDeleted.message)
					.textStyle(.body1Regular)
					.foregroundColor(.primaryText)

				Spacer()
			}
			.multilineTextAlignment(.center)
			.padding(.horizontal, .large2)
			.padding(.top, .huge1)
		}
		.footer {
			Button(L10n.AccountSettings.AccountDeleted.button, action: onGoHome)
				.buttonStyle(.primaryRectangular)
		}
		.toolbar(.hidden)
	}
}
