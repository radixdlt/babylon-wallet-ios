// MARK: - RecoverWalletControlWithBDFSComplete.View
extension RecoverWalletControlWithBDFSComplete {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<RecoverWalletControlWithBDFSComplete>

		init(store: StoreOf<RecoverWalletControlWithBDFSComplete>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			ScrollView {
				VStack(spacing: .zero) {
					Text(L10n.RecoverWalletWithoutProfile.Complete.headerTitle)
						.multilineTextAlignment(.center)
						.textStyle(.sheetTitle)
						.foregroundStyle(.primaryText)
						.padding(.top, .medium3)
						.padding(.horizontal, .large1)
						.padding(.bottom, .large3)

					Text(LocalizedStringKey(L10n.RecoverWalletWithoutProfile.Complete.headerSubtitle))
						.multilineTextAlignment(.leading)
						.textStyle(.body1Regular)
						.foregroundStyle(.primaryText)
						.flushedLeft
						.padding(.horizontal, .large2)
						.padding(.bottom, .huge3)

					Spacer(minLength: 0)
				}
			}
			.background(.primaryBackground)
			.footer {
				Button(L10n.RecoverWalletWithoutProfile.Complete.continueButton) {
					store.send(.view(.continueButtonTapped))
				}
				.buttonStyle(.primaryRectangular(shouldExpand: true))
			}
			.navigationBarBackButtonHidden()
		}
	}
}
