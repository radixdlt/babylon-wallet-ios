import DisplayEntitiesControlledByMnemonicFeature
import FeaturePrelude
import ImportMnemonicFeature

extension ImportMnemonicControllingAccounts.State {
	var viewState: ImportMnemonicControllingAccounts.ViewState {
		.init(isSkippable: entitiesControlledByFactorSource.isSkippable)
	}
}

// MARK: - ImportMnemonicControllingAccounts.View
extension ImportMnemonicControllingAccounts {
	public struct ViewState: Equatable {
		let isSkippable: Bool

		var title: LocalizedStringKey {
			isSkippable ? "The following **Accounts** are controlled by a seed phrase. To recover control, you must re-enter it." : "Your **Personas** and the following **Accounts** are controlled by your main seed phrase. To recover control, you must re-enter it."
		}

		var navigationTitle: LocalizedStringKey {
			isSkippable ? "Seed Phrase Import" : "Main Seed Phrase"
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
						.textStyle(.body1Regular)
						.foregroundColor(.app.gray1)
						.padding()

					if viewStore.isSkippable {
						Button("Skip This Seed Phrase For Now") {
							viewStore.send(.skip)
						}
						.foregroundColor(.app.blue2)
						.font(.app.body1Regular)
						.frame(height: .standardButtonHeight)
						.frame(maxWidth: .infinity)
						.padding(.medium1)
						.background(.app.white)
						.cornerRadius(.small2)
					}

					ScrollView {
						DisplayEntitiesControlledByMnemonic.View(
							store: store.scope(state: \.entities, action: { .child(.entities($0)) })
						)
					}
				}
				.sheet(
					store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
					state: /ImportMnemonicControllingAccounts.Destinations.State.importMnemonic,
					action: ImportMnemonicControllingAccounts.Destinations.Action.importMnemonic,
					content: { store_ in
						NavigationView {
							ImportMnemonic.View(store: store_)
								// FIXME: Strings
								.navigationTitle("Enter Seed Phrase")
						}
					}
				)
				.padding(.horizontal, .medium3)
				.footer {
					// FIXME: Strings
					Button("Enter This Seed Phrase") {
						viewStore.send(.inputMnemonic)
					}
					.buttonStyle(.primaryRectangular)
				}
				.navigationTitle(viewStore.navigationTitle)
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
