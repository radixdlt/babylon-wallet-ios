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

		public var isStoryValid: Bool {
			!story.isEmpty
		}

		public var isBackupValid: Bool {
			!backup.isEmpty
		}

		public var saveWithDescriptionControlState: ControlState {
			isStoryValid && isBackupValid ? .enabled : .disabled
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
						primaryHeading: .init(text: L10n.ImportMnemonic.OffDevice.storyPrimaryHeading),
						secondaryHeading: L10n.Common.optional,
						placeholder: L10n.ImportMnemonic.OffDevice.storyPlaceholder,
						text: viewStore.binding(
							get: \.story,
							send: { .storyChanged($0) }
						),
						hint: .info(L10n.ImportMnemonic.OffDevice.storyHint)
					)

					AppTextField(
						primaryHeading: .init(text: L10n.ImportMnemonic.OffDevice.locationPrimaryHeading),
						secondaryHeading: L10n.Common.optional,
						placeholder: L10n.ImportMnemonic.OffDevice.locationPlaceholder,
						text: viewStore.binding(
							get: \.backup,
							send: { .backupChanged($0) }
						),
						hint: .info(L10n.ImportMnemonic.OffDevice.locationHint)
					)
				}
				.padding()
				.footer {
					Button(L10n.ImportMnemonic.OffDevice.saveWithDescription) {
						viewStore.send(.saveButtonTapped)
					}
					.buttonStyle(.primaryRectangular)
					.controlState(viewStore.saveWithDescriptionControlState)

					Button(L10n.ImportMnemonic.OffDevice.saveWithoutDescription) {
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
