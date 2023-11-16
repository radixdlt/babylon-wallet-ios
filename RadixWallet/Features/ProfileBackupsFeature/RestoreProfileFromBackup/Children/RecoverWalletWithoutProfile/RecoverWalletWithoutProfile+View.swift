extension RecoverWalletWithoutProfile.State {
	var viewState: RecoverWalletWithoutProfile.ViewState {
		.init()
	}
}

// MARK: - RecoverWalletWithoutProfile.View
extension RecoverWalletWithoutProfile {
	public struct ViewState: Equatable {
		// TODO: declare some properties
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<RecoverWalletWithoutProfile>

		public init(store: StoreOf<RecoverWalletWithoutProfile>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { _ in
				ScrollView {
					VStack(alignment: .center, spacing: .large1) {
						Text("Recover Control Without Backup")
							.textStyle(.sheetTitle)

						Text("If you have no wallet backup in the cloud or as an exported backup file, you still have other restore options.")

						Divider()

						Text("**I have my main “Babylon” 24-word seed phrase.**")

						Button("“Babylon” seed phrase restore") {
							store.send(.view(.recoverWithBDFSTapped))
						}
						.buttonStyle(.secondaryRectangular)

						Divider()

						Text("**I only want to restore Ledger hardware wallet Accounts**")

						Text("OR")

						Text("**I only have Accounts created on the Radix Olympia Network**")

						Button("Ledger-only or Olmypia-only Restore") {
							store.send(.view(.ledgerOnlyOrOlympiaOnlyTapped))
						}
						.buttonStyle(.secondaryRectangular)
					}
					.multilineTextAlignment(.center)
					.padding()
				}
				.withNavigationBar { store.send(.view(.closeTapped)) }
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - RecoverWalletWithoutProfile_Preview
struct RecoverWalletWithoutProfile_Preview: PreviewProvider {
	static var previews: some View {
		RecoverWalletWithoutProfile.View(
			store: .init(
				initialState: .previewValue,
				reducer: RecoverWalletWithoutProfile.init
			)
		)
	}
}

extension RecoverWalletWithoutProfile.State {
	public static let previewValue = Self()
}
#endif
