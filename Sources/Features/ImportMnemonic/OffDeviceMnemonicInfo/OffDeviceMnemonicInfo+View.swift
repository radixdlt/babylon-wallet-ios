import FeaturePrelude

extension OffDeviceMnemonicInfo.State {
	var viewState: OffDeviceMnemonicInfo.ViewState {
		.init(story: story, backup: backup)
	}
}

// MARK: - OffDeviceMnemonicInfo.View
extension OffDeviceMnemonicInfo {
	public struct ViewState: Equatable {
		public let story: String
		public let backup: String
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<OffDeviceMnemonicInfo>

		public init(store: StoreOf<OffDeviceMnemonicInfo>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack(spacing: .large1) {
					AppTextField(
						primaryHeading: "Tell a story", // FIXME: strings
						secondaryHeading: "Optional",
						placeholder: "Hitchcock's The Birds mixed with Office space",
						text: viewStore.binding(
							get: \.story,
							send: { .storyChanged($0) }
						),
						// FIXME: strings
						hint: .info("Without revealing the words, what comes to mind when reading this seed phrase?")
					)

					AppTextField(
						primaryHeading: "Backup location?", // FIXME: strings
						secondaryHeading: "Optional",
						placeholder: "In that book my mother used to read to me at my best childhoods summer vacation place",
						text: viewStore.binding(
							get: \.backup,
							send: { .backupChanged($0) }
						),
						// FIXME: strings
						hint: .info("Without revealing location, vague hint on where this mnemonic is backed up, if anywhere.")
					)
				}
				.padding()
				.footer {
					// FIXME: strings
					Button("Save") {
						viewStore.send(.saveButtonTapped)
					}
					.buttonStyle(.primaryRectangular)

					Button("Skip") {
						viewStore.send(.skipButtonTapped)
					}
					.buttonStyle(.secondaryRectangular(shouldExpand: true))
				}
			}
		}
	}
}

// #if DEBUG
// import SwiftUI // NB: necessary for previews to appear
//
//// MARK: - OffDeviceMnemonicInfo_Preview
// struct OffDeviceMnemonicInfo_Preview: PreviewProvider {
//	static var previews: some View {
//		OffDeviceMnemonicInfo.View(
//			store: .init(
//				initialState: .previewValue,
//				reducer: OffDeviceMnemonicInfo()
//			)
//		)
//	}
// }
//
// extension OffDeviceMnemonicInfo.State {
//	public static let previewValue = Self()
// }
// #endif
