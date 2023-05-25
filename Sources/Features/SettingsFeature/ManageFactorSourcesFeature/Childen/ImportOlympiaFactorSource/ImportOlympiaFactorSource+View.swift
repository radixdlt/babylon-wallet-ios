import Cryptography
import FeaturePrelude
import ImportMnemonicFeature

extension ImportOlympiaFactorSource.State {
	var viewState: ImportOlympiaFactorSource.ViewState {
		.init(
			canTapAlreadyImportedButton: canTapAlreadyImportedButton
		)
	}
}

// MARK: - ImportOlympiaFactorSource.View
extension ImportOlympiaFactorSource {
	public struct ViewState: Equatable {
		let canTapAlreadyImportedButton: Bool
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
					ImportMnemonic.View(
						store: store.scope(
							state: \.importMnemonic,
							action: { .child(.importMnemonic($0)) }
						)
					)

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
