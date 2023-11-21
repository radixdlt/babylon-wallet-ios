extension RecoverWalletControlWithBDFSComplete.State {
	var viewState: RecoverWalletControlWithBDFSComplete.ViewState {
		.init()
	}
}

// MARK: - RecoverWalletControlWithBDFSComplete.View

public extension RecoverWalletControlWithBDFSComplete {
	struct ViewState: Equatable {
		// TODO: declare some properties
	}

	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<RecoverWalletControlWithBDFSComplete>

		public init(store: StoreOf<RecoverWalletControlWithBDFSComplete>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { _ in
				VStack {
					Text("Recovery completed")

					Text("Accounts discovered in the scan have been added to your wallet.\n\nIf you have any Olympia or “Legacy” Accounts to import - or any Accounts using a Ledger hardware wallet device - please use the **Account Recovery Scan** option in your Radix Wallet settings under **Account Security**.")

					Spacer(minLength: 0)

					Button("Continue") {
						store.send(.view(.continueTapped))
					}.buttonStyle(.secondaryRectangular)
				}
				.padding()
				.background(Color.blue)
				.foregroundColor(.white)
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - RecoverWalletControlWithBDFSComplete_Preview

struct RecoverWalletControlWithBDFSComplete_Preview: PreviewProvider {
	static var previews: some View {
		RecoverWalletControlWithBDFSComplete.View(
			store: .init(
				initialState: .previewValue,
				reducer: RecoverWalletControlWithBDFSComplete.init
			)
		)
	}
}

public extension RecoverWalletControlWithBDFSComplete.State {
	static let previewValue = Self()
}
#endif
