import ComposableArchitecture
import SwiftUI

extension ImportMnemonicControllingAccounts.State {
	var viewState: ImportMnemonicControllingAccounts.ViewState {
		.init(isMain: isMainBDFS)
	}
}

// MARK: - ImportMnemonicControllingAccounts.View
extension ImportMnemonicControllingAccounts {
	struct ViewState: Equatable {
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
			isMain ? L10n.RecoverSeedPhrase.noMainSeedPhraseButton : L10n.RecoverSeedPhrase.skipButton
		}
	}

	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<ImportMnemonicControllingAccounts>

		init(store: StoreOf<ImportMnemonicControllingAccounts>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				ScrollView {
					VStack(spacing: 0) {
						Text(viewStore.navigationTitle)
							.textStyle(.sheetTitle)
							.foregroundColor(.primaryText)
							.multilineTextAlignment(.center)
							.padding(.bottom, .medium2)

						Text(viewStore.subtitle)
							.textStyle(.body1Regular)
							.foregroundColor(.primaryText)
							.padding(.bottom, .medium3)

						DisplayEntitiesControlledByMnemonic.View(
							store: store.scope(state: \.entities, action: { .child(.entities($0)) })
						)

						Spacer(minLength: 0)
					}
					.padding(.horizontal, .medium3)
				}
				.footer {
					skipButton(title: viewStore.skipButtonTitle)

					Button(L10n.RecoverSeedPhrase.enterButton) {
						viewStore.send(.inputMnemonicButtonTapped)
					}
					.buttonStyle(.primaryRectangular)
				}
				.onAppear { viewStore.send(.appeared) }
				.destinations(with: store)
			}
		}

		private func skipButton(title: String) -> some SwiftUI.View {
			Button(title) {
				store.send(.view(.skipButtonTapped))
			}
			.foregroundColor(.app.blue2)
			.font(.app.body1Header)
			.frame(height: .standardButtonHeight)
			.frame(maxWidth: .infinity)
			.background(.primaryBackground)
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
		sheet(store: destinationStore.scope(state: \.importMnemonic, action: \.importMnemonic)) { store in
			ImportMnemonic.View(store: store)
				// TODO: Consider moving this into the view that should always set toolbar instead of using header
				.radixToolbar(title: L10n.EnterSeedPhrase.Header.title, alwaysVisible: false)
				.inNavigationStack
		}
	}

	private func confirmSkippingBDFS(with destinationStore: PresentationStoreOf<ImportMnemonicControllingAccounts.Destination>) -> some View {
		sheet(store: destinationStore.scope(state: \.confirmSkippingBDFS, action: \.confirmSkippingBDFS)) {
			ConfirmSkippingBDFS.View(store: $0)
				.inNavigationStack
		}
	}
}
