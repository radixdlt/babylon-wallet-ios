import Cryptography
import FeaturePrelude

extension ImportOlympiaFactorSource.State {
	var viewState: ImportOlympiaFactorSource.ViewState {
		.init(
			mnemonic: mnemonic,
			passphrase: passphrase,
			expectedWordCount: expectedWordCount.wordCount,
			canTapAlreadyImportedButton: canTapAlreadyImportedButton,
			focusedField: focusedField
		)
	}
}

// MARK: - ImportOlympiaFactorSource.View
extension ImportOlympiaFactorSource {
	public struct ViewState: Equatable {
		let mnemonic: String
		let passphrase: String
		let expectedWordCount: Int
		let canTapAlreadyImportedButton: Bool
		@BindingState public var focusedField: ImportOlympiaFactorSource.State.Field?
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<ImportOlympiaFactorSource>
		@FocusState private var focusedField: ImportOlympiaFactorSource.State.Field?

		public init(store: StoreOf<ImportOlympiaFactorSource>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack {
					Text("Input #\(viewStore.expectedWordCount) words")

					let focusedFieldBinding = viewStore.binding(
						get: \.focusedField,
						send: { .textFieldFocused($0) }
					)

					AppTextField(
						placeholder: "Mnemonic",
						text: viewStore.binding(
							get: \.mnemonic,
							send: { .mnemonicChanged($0) }
						),
						hint: .info("Seed phrase"),
						focus: .on(.mnemonic, binding: focusedFieldBinding, to: $focusedField)
					)
					.autocorrectionDisabled()

					AppTextField(
						placeholder: "Passphrase",
						text: viewStore.binding(
							get: \.passphrase,
							send: { .passphraseChanged($0) }
						),
						hint: .info("BIP39 Passphrase is often called a '25th word'."),
						focus: .on(.passphrase, binding: focusedFieldBinding, to: $focusedField)
					)
					.autocorrectionDisabled()

					Button("Import") {
						viewStore.send(.importButtonTapped)
					}
					.buttonStyle(.primaryRectangular)

					Button("Already imported") {
						viewStore.send(.alreadyImportedButtonTapped)
					}
					.controlState(viewStore.canTapAlreadyImportedButton ? .enabled : .disabled)
					.buttonStyle(.secondaryRectangular(shouldExpand: true))
				}
				.padding([.horizontal, .bottom], .medium1)
				.alert(
					store: store.scope(
						state: \.$foundNoExistFactorSourceAlert,
						action: { .view(.foundNoExistFactorSourceAlert($0)) }
					)
				)
				.onAppear { viewStore.send(.appeared) }
				#if os(iOS)
					.navigationBarTitleColor(.app.gray1)
					.navigationBarTitleDisplayMode(.inline)
					.navigationBarInlineTitleFont(.app.secondaryHeader)
				#endif
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - ImportOlympiaFactorSource_Preview
struct ImportOlympiaFactorSource_Preview: PreviewProvider {
	static var previews: some View {
		ImportOlympiaFactorSource.View(
			store: .init(
				initialState: .previewValue,
				reducer: ImportOlympiaFactorSource()
			)
		)
	}
}

extension ImportOlympiaFactorSource.State {
	public static let previewValue = Self()
}
#endif
