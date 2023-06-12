import FeaturePrelude

extension OffDeviceMnemonicInfo.State {
	var viewState: OffDeviceMnemonicInfo.ViewState {
		.init(label: label)
	}
}

// MARK: - OffDeviceMnemonicInfo.View
extension OffDeviceMnemonicInfo {
	public struct ViewState: Equatable {
		public let label: String

		public var isLabelValid: Bool {
			!label.isEmpty
		}

		public var saveButtonControlState: ControlState {
			isLabelValid ? .enabled : .disabled
		}
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
						primaryHeading: .init(text: "Label"), // FIXME: strings
						placeholder: "Label", // FIXME: strings
						text: viewStore.binding(
							get: \.label,
							send: { .labelChanged($0) }
						),
						hint: .info(L10n.ImportMnemonic.OffDevice.storyHint) // FIXME: rename key
					)
				}
				.padding()
				.footer {
					Button("Save external seed phrase") { // FIXME: strings
						viewStore.send(.saveButtonTapped)
					}
					.buttonStyle(.primaryRectangular)
					.controlState(viewStore.saveButtonControlState)
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
