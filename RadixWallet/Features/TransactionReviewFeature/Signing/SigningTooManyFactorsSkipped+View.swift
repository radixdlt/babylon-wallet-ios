import SwiftUI

extension SigningTooManyFactorsSkipped.State {
	var title: String {
		switch intent {
		case .transaction:
			L10n.TransactionRecovery.Transaction.title
		case .preAuth:
			L10n.TransactionRecovery.PreAuthorization.title
		}
	}

	var message: String {
		switch intent {
		case .transaction:
			L10n.TransactionRecovery.Transaction.message
		case .preAuth:
			L10n.TransactionRecovery.PreAuthorization.message
		}
	}
}

// MARK: - SigningTooManyFactorsSkipped.View
extension SigningTooManyFactorsSkipped {
	struct View: SwiftUI.View {
		let store: StoreOf<SigningTooManyFactorsSkipped>
		@Environment(\.dismiss) var dismiss

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				VStack(spacing: .medium1) {
					Text(store.title)
						.textStyle(.sheetTitle)
						.foregroundStyle(.primaryText)
						.multilineTextAlignment(.center)

					Text(store.message)
						.textStyle(.body1HighImportance)
						.foregroundStyle(.primaryText)
						.multilineTextAlignment(.center)

					Spacer()
				}
				.padding(.horizontal, .medium1)
				.footer {
					VStack(spacing: .medium1) {
						Button(L10n.TransactionRecovery.restart) {
							store.send(.view(.restartButtonTapped))
						}
						.buttonStyle(.primaryRectangular)

						Button(L10n.TransactionRecovery.Transaction.cancel) {
							store.send(.view(.cancelButtonTapped))
						}
						.buttonStyle(.blueText)
					}
				}
				.withNavigationBar {
					dismiss()
				}
			}
		}
	}
}
