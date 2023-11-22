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

		var navigationTitle: String {
			isMain
				? L10n.RecoverSeedPhrase.Header.titleMain
				: L10n.RecoverSeedPhrase.Header.titleOther
		}

		var subtitle: LocalizedStringKey {
			.init(
				isMain
					? L10n.RecoverSeedPhrase.Header.subtitleMainSeedPhrase
					: L10n.RecoverSeedPhrase.Header.subtitleOtherSeedPhrase
			)
		}

		var skipButtonTitle: String {
			// FIXME: Strings
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
				VStack(alignment: .center) {
					Text(viewStore.navigationTitle)
						.textStyle(.sheetTitle)
						.foregroundColor(.app.gray1)
						.multilineTextAlignment(.center)
						.padding(.bottom, .small1)

					Text(viewStore.subtitle)
						.textStyle(.body1Regular)
						.foregroundColor(.app.gray1)

					ScrollView {
						DisplayEntitiesControlledByMnemonic.View(
							store: store.scope(state: \.entities, action: { .child(.entities($0)) })
						)
					}

					Spacer(minLength: 0)
				}
				.padding(.horizontal, .medium3)
				.footer {
					skipButton(title: viewStore.skipButtonTitle)

					Button(L10n.RecoverSeedPhrase.enterButton) {
						viewStore.send(.inputMnemonic)
					}
					.buttonStyle(.primaryRectangular)
				}
				.onAppear { viewStore.send(.appeared) }
				.destinations(with: store)
			}
		}

		private func skipButton(title: String) -> some SwiftUI.View {
			Button(title) {
				store.send(.view(.skip))
			}
			.foregroundColor(.app.blue2)
			.font(.app.body1Header)
			.frame(height: .standardButtonHeight)
			.frame(maxWidth: .infinity)
			.padding(.medium1)
			.background(.app.white)
			.cornerRadius(.small2)
		}
	}
}

private extension StoreOf<ImportMnemonicControllingAccounts> {
	var destination: PresentationStoreOf<ImportMnemonicControllingAccounts.Destination> {
		func scopeState(state: State) -> PresentationState<ImportMnemonicControllingAccounts.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<ImportMnemonicControllingAccounts>) -> some View {
		let destinationStore = store.destination
		return importMnemonic(with: destinationStore)
			.confirmSkippingBDFS(with: destinationStore)
	}

	private func importMnemonic(with destinationStore: PresentationStoreOf<ImportMnemonicControllingAccounts.Destination>) -> some View {
		sheet(
			store: destinationStore,
			state: /ImportMnemonicControllingAccounts.Destination.State.importMnemonic,
			action: ImportMnemonicControllingAccounts.Destination.Action.importMnemonic,
			content: {
				ImportMnemonic.View(store: $0)
					.navigationTitle(L10n.EnterSeedPhrase.Header.title)
					.inNavigationView
			}
		)
	}

	private func confirmSkippingBDFS(with destinationStore: PresentationStoreOf<ImportMnemonicControllingAccounts.Destination>) -> some View {
		sheet(
			store: destinationStore,
			state: /ImportMnemonicControllingAccounts.Destination.State.confirmSkippingBDFS,
			action: ImportMnemonicControllingAccounts.Destination.Action.confirmSkippingBDFS,
			content: {
				ConfirmSkippingBDFS.View(store: $0)
					.inNavigationStack
			}
		)
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
