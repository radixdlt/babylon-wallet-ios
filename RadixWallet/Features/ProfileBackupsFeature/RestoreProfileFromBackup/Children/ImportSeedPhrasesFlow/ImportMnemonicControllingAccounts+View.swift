import ComposableArchitecture
import SwiftUI
extension ImportMnemonicControllingAccounts.State {
	var viewState: ImportMnemonicControllingAccounts.ViewState {
		.init(isMain: isMainBDFS)
	}
}

// MARK: - ImportMnemonicControllingAccounts.View
extension ImportMnemonicControllingAccounts {
	public struct ViewState: Equatable {
		let isMain: Bool

		var title: LocalizedStringKey {
			.init(
				isMain
					? L10n.RecoverSeedPhrase.Header.subtitleMainSeedPhrase
					: L10n.RecoverSeedPhrase.Header.subtitleOtherSeedPhrase
			)
		}

		var navigationTitle: String {
			isMain
				? L10n.RecoverSeedPhrase.Header.titleMain
				: L10n.RecoverSeedPhrase.Header.titleOther
		}

		var skipButtonTitle: String {
			isMain ? "I Don't Have the Main Seed Phrase" : L10n.RecoverSeedPhrase.skipButton
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
					Text(viewStore.title)
						.textStyle(.body1Regular)
						.foregroundColor(.app.gray1)
						.padding()

					if !viewStore.isMain {
						skipButton(with: viewStore)
					}
					ScrollView {
						DisplayEntitiesControlledByMnemonic.View(
							store: store.scope(state: \.entities, action: { .child(.entities($0)) })
						)
					}
					.fixedSize(horizontal: false, vertical: true) // prevent ScrollView from growing vertically if not needed.

					if viewStore.isMain {
						skipButton(with: viewStore)
					}

					Spacer(minLength: 0)
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
				.sheet(
					store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
					state: /ImportMnemonicControllingAccounts.Destinations.State.confirmSkippingBDFS,
					action: ImportMnemonicControllingAccounts.Destinations.Action.confirmSkippingBDFS,
					content: { store_ in
						NavigationStack {
							ConfirmSkippingBDFS.View(store: store_)
						}
					}
				)
			}
		}

		private func skipButton(with viewStore: ViewStoreOf<ImportMnemonicControllingAccounts>) -> some SwiftUI.View {
			Button(viewStore.skipButtonTitle) {
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
