import FeaturePrelude

extension ImportOlympiaFactorSource.State {
	var viewState: ImportOlympiaFactorSource.ViewState {
		.init()
	}
}

// MARK: - ImportOlympiaFactorSource.View
extension ImportOlympiaFactorSource {
	public struct ViewState: Equatable {
		// TODO: declare some properties
		let mnemonic: String
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<ImportOlympiaFactorSource>

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
						hint: L10n.CreateEntity.NameNewEntity.Name.Field.explanation,
						binding: $focusedField,
						equals: .entityName,
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
