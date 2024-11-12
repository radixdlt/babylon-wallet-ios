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
				if kind != .deleteAccount {
					Image(systemName: "eye.fill")
						.renderingMode(.template)
						.resizable()
						.scaledToFit()
						.frame(.small)
						.foregroundColor(.app.gray3)
				}

				Text(title)
					.textStyle(.sheetTitle)
					.foregroundColor(.app.gray1)

				Text(markdown: message, emphasizedColor: .app.gray1, emphasizedFont: .app.body1Header)
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

				Button(primaryAction) {
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
	enum Kind: Hashable, Sendable {
		case hideAccount
		case hideAsset
		case hideCollection(name: String)
		case deleteAccount
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
		case .deleteAccount: "Delete This Account?"
		}
	}

	var message: String {
		switch kind {
		case .hideAccount: L10n.Confirmation.HideAccount.message
		case .hideAsset: L10n.Confirmation.HideAsset.message
		case let .hideCollection(name): L10n.Confirmation.HideCollection.message(name)
		case .deleteAccount: "You’re about to permanently delete this Account. Once this is done, you will not be able to recover access."
		}
	}

	var primaryAction: String {
		switch kind {
		case .hideAccount: L10n.Confirmation.HideAccount.button
		case .hideAsset: L10n.Confirmation.HideAsset.button
		case .hideCollection: L10n.Confirmation.HideCollection.button
		case .deleteAccount: "Continue"
		}
	}
}
