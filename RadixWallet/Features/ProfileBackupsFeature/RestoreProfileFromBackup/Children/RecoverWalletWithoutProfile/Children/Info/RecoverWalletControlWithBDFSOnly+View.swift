// MARK: - RecoverWalletControlWithBDFSOnly.View

public extension RecoverWalletControlWithBDFSOnly {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<RecoverWalletControlWithBDFSOnly>

		public init(store: StoreOf<RecoverWalletControlWithBDFSOnly>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			VStack(alignment: .center, spacing: .medium2) {
				// FIXME: Strings
				Text("Recover Control Without Backup")
					.textStyle(.sheetTitle)
					.multilineTextAlignment(.center)

				// FIXME: Strings
				Text("**If you have no wallet backup in the cloud or as an exported backup file**, you can still restore Account access only using your main “Babylon” seed phrase. You cannot recover your Account names or other wallet settings this way.\n\nYou will be asked to enter the primary seed phrase. There are **24 words** that the Radix Wallet mobile app showed you to write down and save securely.")
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
