
// MARK: - RecoverWalletControlWithBDFSComplete.View

public extension RecoverWalletControlWithBDFSComplete {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<RecoverWalletControlWithBDFSComplete>

		public init(store: StoreOf<RecoverWalletControlWithBDFSComplete>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			VStack(alignment: .leading, spacing: .medium1) {
				// FIXME: Strings
				Text("Recovery completed")
					.textStyle(.sheetTitle)
					.multilineTextAlignment(.center)

				// FIXME: Strings
				Text("Accounts discovered in the scan have been added to your wallet.\n\nIf you have any Olympia or “Legacy” Accounts to import - or any Accounts using a Ledger hardware wallet device - please use the **Account Recovery Scan** option in your Radix Wallet settings under **Account Security**.")
					.multilineTextAlignment(.leading)

				Spacer(minLength: 0)
			}
			.textStyle(.body1Regular)
			.foregroundColor(.app.gray1)
			.padding()
			.footer {
				// FIXME: Strings
				Button("Continue") {
					store.send(.view(.continueTapped))
				}
				.buttonStyle(.primaryRectangular)
			}
		}
	}
}
