import FeaturePrelude

extension ImportOlympiaFactorSource.State {
	var viewState: ImportOlympiaFactorSource.ViewState {
		.init(mnemonic: mnemonic, passphrase: passphrase, focusedField: focusedField)
	}
}

// MARK: - ImportOlympiaFactorSource.View
extension ImportOlympiaFactorSource {
	public struct ViewState: Equatable {
		let mnemonic: String
		let passphrase: String
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
					AppTextField(
						placeholder: "Mnemonic",
						text: viewStore.binding(
							get: \.mnemonic,
							send: { .mnemonicChanged($0) }
						),
						hint: "Seed phrase",
						binding: $focusedField,
						equals: .mnemonic,
						first: viewStore.binding(
							get: \.focusedField,
							send: { .textFieldFocused($0) }
						)
					)
					.autocorrectionDisabled()

					AppTextField(
						placeholder: "Passphrase",
						text: viewStore.binding(
							get: \.passphrase,
							send: { .passphraseChanged($0) }
						),
						hint: "BIP39 Passphrase is often called a '25th word'.",
						binding: $focusedField,
						equals: .passphrase,
						first: viewStore.binding(
							get: \.focusedField,
							send: { .textFieldFocused($0) }
						)
					)
					.autocorrectionDisabled()
				}
				.onAppear { viewStore.send(.appeared) }
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
