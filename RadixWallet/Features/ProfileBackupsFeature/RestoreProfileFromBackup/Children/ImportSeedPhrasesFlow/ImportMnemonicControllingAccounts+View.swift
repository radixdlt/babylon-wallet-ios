import ComposableArchitecture
import SwiftUI
extension ImportMnemonicControllingAccounts.State {
	var viewState: ImportMnemonicControllingAccounts.ViewState {
		.init(isSkippable: entitiesControlledByFactorSource.isSkippable)
	}
}

// MARK: - ImportMnemonicControllingAccounts.View
extension ImportMnemonicControllingAccounts {
	public struct ViewState: Equatable {
		let isSkippable: Bool
		let title: LocalizedStringKey
		let navigationTitle: String

		init(isSkippable: Bool) {
			self.isSkippable = isSkippable
			if isSkippable {
				self.title = .init(L10n.RecoverSeedPhrase.Header.subtitleOtherSeedPhrase)
				self.navigationTitle = L10n.RecoverSeedPhrase.Header.titleOther
			} else {
				self.title = .init(L10n.RecoverSeedPhrase.Header.subtitleMainSeedPhrase)
				self.navigationTitle = L10n.RecoverSeedPhrase.Header.titleMain
			}
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

					if viewStore.isSkippable {
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
				.destinations(with: store)
			}
		}
	}
}

private extension StoreOf<ImportMnemonicControllingAccounts> {
	var destination: PresentationStoreOf<ImportMnemonicControllingAccounts.Destination> {
		scope(state: \.$destination) { .destination($0) }
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<ImportMnemonicControllingAccounts>) -> some View {
		let destinationStore = store.destination
		return importMnemonic(with: destinationStore)
	}

	private func importMnemonic(with destinationStore: PresentationStoreOf<ImportMnemonicControllingAccounts.Destination>) -> some View {
		sheet(
			store: destinationStore,
			state: /ImportMnemonicControllingAccounts.Destination.State.importMnemonic,
			action: ImportMnemonicControllingAccounts.Destination.Action.importMnemonic,
			content: { store in
				ImportMnemonic.View(store: store)
					.navigationTitle(L10n.EnterSeedPhrase.Header.title)
					.inNavigationView
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
