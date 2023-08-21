import FeaturePrelude

extension ImportMnemonicControllingAccounts.State {
	var viewState: ImportMnemonicControllingAccounts.ViewState {
		.init(isSkippable: mnemonicToImport.isSkippable)
	}
}

// MARK: - ImportMnemonicControllingAccounts.View
extension ImportMnemonicControllingAccounts {
	public struct ViewState: Equatable {
		let isSkippable: Bool

		var title: LocalizedStringKey {
			isSkippable ? "The following Accounts are controlled by a seed phrase. To recover control, you must re-enter it." : "Your Personas and the following Accounts are controlled by your main seed phrase. To recover control, you must re-enter it."
		}
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<ImportMnemonicControllingAccounts>

		public init(store: StoreOf<ImportMnemonicControllingAccounts>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack {
					// FIXME: Strings
					Text(viewStore.title)

					if viewStore.isSkippable {
						Button("Skip This Seed Phrase For Now") {
							viewStore.send(.skip)
						}
					}

					ScrollView {
						ForEach(["A", "B"], id: \.self) {
							Text("\($0)")
						}
					}
				}
				.footer {
					// FIXME: Strings
					Button("Enter This Seed Phrase") {
						viewStore.send(.inputMnemonic)
					}
				}
				.onAppear { viewStore.send(.appeared) }
			}
		}
	}
}

// #if DEBUG
// import SwiftUI // NB: necessary for previews to appear
//
//// MARK: - ImportMnemonicControllingAccounts_Preview
// struct ImportMnemonicControllingAccounts_Preview: PreviewProvider {
//	static var previews: some View {
//		ImportMnemonicControllingAccounts.View(
//			store: .init(
//				initialState: .previewValue,
//				reducer: ImportMnemonicControllingAccounts()
//			)
//		)
//	}
// }
//
// extension ImportMnemonicControllingAccounts.State {
//	public static let previewValue = Self()
// }
// #endif
