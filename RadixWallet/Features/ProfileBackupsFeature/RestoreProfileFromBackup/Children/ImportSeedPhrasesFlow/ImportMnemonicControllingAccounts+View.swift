import ComposableArchitecture
import SwiftUI
extension ImportMnemonicControllingAccounts.State {
	var viewState: ImportMnemonicControllingAccounts.ViewState {
		.init(isSkippable: entitiesControlledByFactorSource.isSkippable, disableSkipImport: disableSkipImport)
	}
}

// MARK: - ImportMnemonicControllingAccounts.View
extension ImportMnemonicControllingAccounts {
	public struct ViewState: Equatable {
		let isSkippable: Bool
		let disableSkipImport: Bool

		var title: LocalizedStringKey {
			.init(
				isSkippable
					? L10n.RecoverSeedPhrase.Header.subtitleOtherSeedPhrase
					: L10n.RecoverSeedPhrase.Header.subtitleMainSeedPhrase
			)
		}

		var navigationTitle: String {
			isSkippable
				? L10n.RecoverSeedPhrase.Header.titleOther
				: L10n.RecoverSeedPhrase.Header.titleMain
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

					if !viewStore.disableSkipImport, viewStore.isSkippable {
						Button(L10n.RecoverSeedPhrase.skipButton) {
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
				.padding(.horizontal, .medium3)
				.footer {
					Button(L10n.RecoverSeedPhrase.enterButton) {
						viewStore.send(.inputMnemonic)
					}
					.buttonStyle(.primaryRectangular)
				}
				.navigationTitle(viewStore.navigationTitle)
				.onAppear { viewStore.send(.appeared) }
				.sheet(
					store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
					state: /ImportMnemonicControllingAccounts.Destinations.State.importMnemonic,
					action: ImportMnemonicControllingAccounts.Destinations.Action.importMnemonic,
					content: { store_ in
						NavigationView {
							ImportMnemonic.View(store: store_)
								.navigationTitle(L10n.EnterSeedPhrase.Header.title)
						}
					}
				)
			}
		}
	}
}

// #if DEBUG
// import SwiftUI
import ComposableArchitecture //
//// MARK: - ImportMnemonicControllingAccounts_Preview
// struct ImportMnemonicControllingAccounts_Preview: PreviewProvider {
//	static var previews: some View {
//		ImportMnemonicControllingAccounts.View(
//			store: .init(
//				initialState: .previewValue,
//				reducer: ImportMnemonicControllingAccounts.init
//			)
//		)
//	}
// }
//
// extension ImportMnemonicControllingAccounts.State {
//	public static let previewValue = Self()
// }
// #endif
