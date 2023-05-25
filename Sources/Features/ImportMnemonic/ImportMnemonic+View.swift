import Cryptography
import FeaturePrelude

extension ImportMnemonic.State {
	var viewState: ImportMnemonic.ViewState {
		.init(
			rowCount: rowCount,
			isAddRowButtonEnabled: isAddRowButtonEnabled,
			isRemoveRowButtonEnabled: isRemoveRowButtonEnabled,
			mnemonic: mnemonic,
			bip39Passphrase: bip39Passphrase
		)
	}

	var rowCount: Int {
		words.count / wordsPerRow
	}
}

// MARK: - ImportMnemonic.View
extension ImportMnemonic {
	public struct ViewState: Equatable {
		let rowCount: Int
		let isAddRowButtonEnabled: Bool
		let isRemoveRowButtonEnabled: Bool
		let mnemonic: Mnemonic?
		let bip39Passphrase: String
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<ImportMnemonic>

		public init(store: StoreOf<ImportMnemonic>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack {
					GeometryReader { geoProxy in
						ScrollView {
							LazyVGrid(
								columns: .init(
									repeating: .init(
										.adaptive(minimum: geoProxy.frame(in: .local).width / CGFloat(wordsPerRow)),
										spacing: .small2,
										alignment: .top
									),
									count: 3
								)
							) {
								ForEachStore(
									store.scope(state: \.words, action: { .child(.word(id: $0, child: $1)) }),
									content: { importMnemonicWordStore in
										VStack(spacing: 0) {
											ImportMnemonicWord.View(store: importMnemonicWordStore)
											Spacer(minLength: .medium2)
										}
									}
								)
							}
						}
					}

					HStack {
						Button {
							viewStore.send(.removeRowButtonTapped)
						} label: {
							HStack {
								Text("3 less words")
									.foregroundColor(viewStore.isRemoveRowButtonEnabled ? .app.gray1 : .app.white)
								Image(systemName: "text.badge.plus")
									.foregroundColor(viewStore.isRemoveRowButtonEnabled ? .app.red1 : .app.white)
							}
						}
						.buttonStyle(.secondaryRectangular)
						.controlState(viewStore.isRemoveRowButtonEnabled ? .enabled : .disabled)

						Button {
							viewStore.send(.addRowButtonTapped)
						} label: {
							HStack {
								Text("3 more words")
									.foregroundColor(viewStore.isAddRowButtonEnabled ? .app.gray1 : .app.white)
								Image(systemName: "text.badge.plus")
									.foregroundColor(viewStore.isAddRowButtonEnabled ? .app.green1 : .app.white)
							}
						}
						.buttonStyle(.secondaryRectangular)
						.controlState(viewStore.isAddRowButtonEnabled ? .enabled : .disabled)
					}

					AppTextField(
						placeholder: "Passphrase",
						text: viewStore.binding(
							get: \.bip39Passphrase,
							send: { .passphraseChanged($0) }
						),
						hint: .info("BIP39 Passphrase is often called a '25th word'.")
					)
					.autocorrectionDisabled()

					.footer {
						WithControlRequirements(
							viewStore.mnemonic,
							forAction: { viewStore.send(.continueButtonTapped($0)) }
						) { action in
							Button("Import mnemonic", action: action)
								.buttonStyle(.primaryRectangular)
						}
					}
				}
				.padding(.medium3)
				.onAppear { viewStore.send(.appeared) }
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - ImportMnemonic_Preview
struct ImportMnemonic_Preview: PreviewProvider {
	static var previews: some View {
		ImportMnemonic.View(
			store: .init(
				initialState: .previewValue,
				reducer: ImportMnemonic()
			)
		)
	}
}

extension ImportMnemonic.State {
	public static let previewValue = Self()
}
#endif
