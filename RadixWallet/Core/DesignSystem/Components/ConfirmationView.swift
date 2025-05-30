import SwiftUI

typealias ConfirmationAction = ConfirmationView.Action

// MARK: - ConfirmationView
struct ConfirmationView: View {
	let kind: Kind
	let onAction: (Action) -> Void

	var body: some View {
		content
			.withNavigationBar {
				onAction(.cancel)
			}
			.presentationDetents([.fraction(0.6)])
			.presentationDragIndicator(.visible)
			.presentationBackground(.blur)
	}

	var content: some View {
		VStack(spacing: .zero) {
			VStack(spacing: .medium2) {
				Image(systemName: "eye.fill")
					.renderingMode(.template)
					.resizable()
					.scaledToFit()
					.frame(.small)
					.foregroundColor(.iconTertiary)

				Text(title)
					.textStyle(.sheetTitle)
					.foregroundColor(.primaryText)

				Text(markdown: message, emphasizedColor: .primaryText, emphasizedFont: .app.body1Header)
					.textStyle(.body1Regular)
					.foregroundColor(.primaryText)
			}
			.padding(.horizontal, .small2)

			Spacer()

			HStack(spacing: .small2) {
				Button(L10n.Common.cancel) {
					onAction(.cancel)
				}
				.buttonStyle(.secondaryRectangular)

				Button(primaryAction) {
					onAction(.confirm)
				}
				.buttonStyle(.primaryRectangular)
			}
		}
		.multilineTextAlignment(.center)
		.padding(.horizontal, .medium1)
		.padding(.bottom, .medium2)
		.background(.primaryBackground)
	}
}

extension ConfirmationView {
	enum Kind: Hashable, Sendable {
		case hideAccount
		case hideAsset
		case hideCollection(name: String)
	}

	enum Action: Sendable {
		case cancel
		case confirm
	}
}

extension ConfirmationView {
	var title: String {
		switch kind {
		case .hideAccount: L10n.Confirmation.HideAccount.title
		case .hideAsset: L10n.Confirmation.HideAsset.title
		case .hideCollection: L10n.Confirmation.HideCollection.title
		}
	}

	var message: String {
		switch kind {
		case .hideAccount: L10n.Confirmation.HideAccount.message
		case .hideAsset: L10n.Confirmation.HideAsset.message
		case let .hideCollection(name): L10n.Confirmation.HideCollection.message(name)
		}
	}

	var primaryAction: String {
		switch kind {
		case .hideAccount: L10n.Confirmation.HideAccount.button
		case .hideAsset: L10n.Confirmation.HideAsset.button
		case .hideCollection: L10n.Confirmation.HideCollection.button
		}
	}
}
