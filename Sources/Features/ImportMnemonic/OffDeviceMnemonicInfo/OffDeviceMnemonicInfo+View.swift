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
				VStack {
					AppTextField(
						primaryHeading: "Tell a story",
						placeholder: "Hitchcock's The Birds mixed with Office space",
						text: viewStore.binding(
							get: \.story,
							send: { .storyChanged($0) }
						),
						hint: .info("Without revealing the words, what comes to mind when reading this seed phrase?")
					)
				}
				.onAppear { viewStore.send(.appeared) }
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
