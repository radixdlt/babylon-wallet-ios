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

						Text("Delete This Account?")
							.textStyle(.sheetTitle)
							.foregroundColor(.app.gray1)

						Text("You’re about to permanently delete this Account. Once this is done, you will not be able to recover access.")
							.textStyle(.body1HighImportance)
							.foregroundColor(.app.gray1)

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

						Button(L10n.Common.cancel) {
							viewStore.send(.view(.cancelButtonTapped))
						}
						.buttonStyle(.primaryText())
					}
					.controlState(viewStore.footerButtonState)
				}
			}
		}
	}
}
