import SwiftUI

public typealias ConfirmationAction = ConfirmationView.Action

// MARK: - ConfirmationView
public struct ConfirmationView: View {
	let configuration: Configuration
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

				Text(configuration.title)
					.textStyle(.sheetTitle)
					.foregroundColor(.app.gray1)

				Text(configuration.message)
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

				Button(configuration.primaryAction) {
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

extension ConfirmationView {
	public struct Configuration {
		let title: String
		let message: String
		let primaryAction: String
	}

	public enum Action: Sendable {
		case cancel
		case confirm
	}
}
