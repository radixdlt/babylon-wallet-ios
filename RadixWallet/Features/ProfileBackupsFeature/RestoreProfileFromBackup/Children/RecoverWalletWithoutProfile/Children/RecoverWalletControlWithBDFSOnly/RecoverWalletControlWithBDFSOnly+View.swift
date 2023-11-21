extension RecoverWalletControlWithBDFSOnly.State {
	var viewState: RecoverWalletControlWithBDFSOnly.ViewState {
		.init()
	}
}

// MARK: - RecoverWalletControlWithBDFSOnly.View

public extension RecoverWalletControlWithBDFSOnly {
	struct ViewState: Equatable {
		// TODO: declare some properties
	}

	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<RecoverWalletControlWithBDFSOnly>

		public init(store: StoreOf<RecoverWalletControlWithBDFSOnly>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { _ in
				VStack(alignment: .leading, spacing: .medium2) {
					Text("Recover Control Without Backup")
						.textStyle(.sheetTitle)

					Text("**If you have no wallet backup in the cloud or as an exported backup file**, you can still restore Account access only using your main “Babylon” seed phrase. You cannot recover your Account names or other wallet settings this way.\n\nYou will be asked to enter the primary seed phrase. There are **24 words** that the Radix Wallet mobile app showed you to write down and save securely.")

					Spacer(minLength: 0)
				}
				.padding()
				.footer {
					Button("Continue") {
						store.send(.view(.continueTapped))
					}
					.buttonStyle(.primaryRectangular)
				}
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - RecoverWalletControlWithBDFSOnly_Preview

struct RecoverWalletControlWithBDFSOnly_Preview: PreviewProvider {
	static var previews: some View {
		RecoverWalletControlWithBDFSOnly.View(
			store: .init(
				initialState: .previewValue,
				reducer: RecoverWalletControlWithBDFSOnly.init
			)
		)
	}
}

public extension RecoverWalletControlWithBDFSOnly.State {
	static let previewValue = Self()
}
#endif
