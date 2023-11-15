// MARK: - ConfirmSkippingBDFS.View
extension ConfirmSkippingBDFS {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<ConfirmSkippingBDFS>

		public init(store: StoreOf<ConfirmSkippingBDFS>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			VStack(spacing: .medium2) {
				// FIXME: Strings
				Text("No Main Seed Phrase?")
					.textStyle(.sheetTitle)
					.padding(.horizontal, -.small2)

				Text("WARNING: If you continue without entering your previous main “Babylon” seed phrase, **you will permanently lose access** to your Personas and any Accounts listed on the previous screen. A new main seed phrase will be created.\n\nTap Continue to proceed with recovering control of any Accounts created with a Ledger hardware wallet, or Accounts you originally created on the Olympia network.")
					.textStyle(.body1Regular)
					.foregroundColor(.app.gray1)
					.multilineTextAlignment(.leading)

				Spacer(minLength: 0)

				// FIXME: Strings
				Button("Continue") {
					store.send(.view(.confirmTapped))
				}
				.buttonStyle(.primaryRectangular)
			}
			.padding(.horizontal, .large3)
			.padding(.bottom, .medium2)
			.toolbar {
				ToolbarItem(placement: .navigationBarLeading) {
					BackButton {
						store.send(.view(.backButtonTapped))
					}
				}
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - ConfirmSkippingBDFS_Preview
struct ConfirmSkippingBDFS_Preview: PreviewProvider {
	static var previews: some View {
		ConfirmSkippingBDFS.View(
			store: .init(
				initialState: .previewValue,
				reducer: ConfirmSkippingBDFS.init
			)
		)
	}
}

extension ConfirmSkippingBDFS.State {
	public static let previewValue = Self()
}
#endif
