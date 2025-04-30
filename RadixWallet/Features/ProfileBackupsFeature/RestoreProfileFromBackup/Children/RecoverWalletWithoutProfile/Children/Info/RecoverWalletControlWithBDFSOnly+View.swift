// MARK: - RecoverWalletControlWithBDFSOnly.View
extension RecoverWalletControlWithBDFSOnly {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<RecoverWalletControlWithBDFSOnly>

		init(store: StoreOf<RecoverWalletControlWithBDFSOnly>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			VStack(alignment: .center, spacing: .medium2) {
				Text(L10n.RecoverWalletWithoutProfile.Info.headerTitle)
					.textStyle(.sheetTitle)
					.multilineTextAlignment(.center)

				Text(LocalizedStringKey(L10n.RecoverWalletWithoutProfile.Info.headerSubtitle))
					.multilineTextAlignment(.leading)

				Spacer(minLength: 0)
			}
			.textStyle(.body1Regular)
			.foregroundColor(.primaryText)
			.padding()
			.footer {
				Button(L10n.RecoverWalletWithoutProfile.Info.continueButton) {
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

extension RecoverWalletControlWithBDFSOnly.State {
	static let previewValue = Self()
}
#endif
