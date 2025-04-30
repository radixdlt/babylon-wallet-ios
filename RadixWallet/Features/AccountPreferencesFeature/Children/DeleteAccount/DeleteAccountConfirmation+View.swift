import ComposableArchitecture
import SwiftUI

// MARK: - DeleteAccountConfirmation.View
extension DeleteAccountConfirmation {
	@MainActor
	struct View: SwiftUI.View {
		let store: StoreOf<DeleteAccountConfirmation>

		var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }) { viewStore in
				ScrollView {
					VStack(spacing: .medium2) {
						Image(.deleteAccount)
							.resizable()
							.frame(.medium)

						Text(L10n.AccountSettings.DeleteAccount.title)
							.textStyle(.sheetTitle)
							.foregroundColor(.primaryText)

						Text(L10n.AccountSettings.DeleteAccount.message)
							.textStyle(.body1HighImportance)
							.foregroundColor(.primaryText)

						Spacer()
					}
					.multilineTextAlignment(.center)
					.padding(.horizontal, .large2)
				}
				.footer {
					VStack(spacing: .medium3) {
						Button(L10n.Common.continue) {
							viewStore.send(.view(.continueButtonTapped))
						}
						.buttonStyle(.primaryRectangular)
					}
					.controlState(viewStore.footerButtonState)
				}
			}
		}
	}
}
