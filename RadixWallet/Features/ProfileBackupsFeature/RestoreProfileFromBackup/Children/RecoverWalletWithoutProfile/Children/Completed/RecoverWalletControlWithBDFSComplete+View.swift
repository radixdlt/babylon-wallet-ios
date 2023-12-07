// MARK: - RecoverWalletControlWithBDFSComplete.View
public extension RecoverWalletControlWithBDFSComplete {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<RecoverWalletControlWithBDFSComplete>

		public init(store: StoreOf<RecoverWalletControlWithBDFSComplete>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			ScrollView {
				VStack(spacing: .zero) {
					Text("Recovery Complete") // FIXME: Strings
						.multilineTextAlignment(.center)
						.textStyle(.sheetTitle)
						.foregroundStyle(.app.gray1)
						.padding(.top, .medium3)
						.padding(.horizontal, .large1)
						.padding(.bottom, .large3)

					Text(LocalizedStringKey(text))
						.multilineTextAlignment(.leading)
						.textStyle(.body1Regular)
						.foregroundStyle(.app.gray1)
						.flushedLeft
						.padding(.horizontal, .large2)
						.padding(.bottom, .huge3)

					Spacer(minLength: 0)
				}
			}
			.footer {
				Button("Continue") { // FIXME: Strings
					store.send(.view(.continueButtonTapped))
				}
				.buttonStyle(.primaryRectangular(shouldExpand: true))
			}
			.navigationBarBackButtonHidden()
		}
	}
}

private let text: String = "Accounts discovered in the scan have been added to your wallet.\n\nIf you have any Olympia or “Legacy” Accounts to import - or any Accounts using a Ledger hardware wallet device - please use the **Account Recovery Scan** option in your Radix Wallet settings under **Account Security**." // FIXME: Strings
