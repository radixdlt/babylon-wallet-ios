import SwiftUI

public typealias HideAccountAction = HideAccountView.Action

// MARK: - HideAccountView
public struct HideAccountView: View {
	let onAction: (Action) -> Void

	public var body: some View {
		content
			.withNavigationBar {
				onAction(.cancel)
			}
			.presentationDetents([.fraction(0.6)])
			.presentationDragIndicator(.visible)
			.presentationBackground(.blur)
	}

	public var content: some View {
		VStack(spacing: .zero) {
			VStack(spacing: .medium2) {
				Image(systemName: "eye.fill")
					.renderingMode(.template)
					.resizable()
					.scaledToFit()
					.frame(.small)
					.foregroundColor(.app.gray3)

				Text(L10n.AccountSettings.HideAccount.title)
					.textStyle(.sheetTitle)
					.foregroundColor(.app.gray1)

				Text(L10n.AccountSettings.HideAccount.message)
					.textStyle(.body1Regular)
					.foregroundColor(.app.gray1)
			}
			.padding(.horizontal, .small2)

			Spacer()

			HStack(spacing: .small2) {
				Button(L10n.Common.cancel) {
					onAction(.cancel)
				}
				.buttonStyle(.secondaryRectangular)

				Button(L10n.AccountSettings.HideAccount.button) {
					onAction(.confirm)
				}
				.buttonStyle(.primaryRectangular)
			}
		}
		.multilineTextAlignment(.center)
		.padding(.horizontal, .medium1)
		.padding(.bottom, .medium2)
	}
}

// MARK: HideAccountView.Action
extension HideAccountView {
	public enum Action: Sendable {
		case cancel
		case confirm
	}
}
