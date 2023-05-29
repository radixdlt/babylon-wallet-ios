import FeaturePrelude

// MARK: - AssetTransferMessage.View
extension AssetTransferMessage {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<AssetTransferMessage>

		@FocusState
		private var focused: Bool

		public init(store: StoreOf<AssetTransferMessage>) {
			self.store = store
		}
	}
}

extension AssetTransferMessage.View {
	public var body: some View {
		WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
			VStack(alignment: .leading) {
				Text("Message")
					.sectionHeading
					.textCase(.uppercase)
					.flushedLeft(padding: .medium3)

				VStack(alignment: .leading, spacing: 0) {
					HStack {
						Button {
							viewStore.send(.messageKindTapped)
						} label: {
							HStack {
								Text("Public")
								Image(asset: AssetResource.chevronDown)
							}
						}
						.textStyle(.body1HighImportance)
						.foregroundColor(.app.gray1)

						Spacer()

						Button("", asset: AssetResource.close) {
							viewStore.send(.removeMessageTapped)
						}
						.foregroundColor(.app.gray2)
					}
					.padding(.medium3)
					.roundedCorners(.top, strokeColor: .borderColor)

					TextEditor(text:
						viewStore.binding(
							get: \.message,
							send: { .messageChanged($0) }
						)
					)
					.focused($focused)
					.frame(minHeight: .transferMessageDefaultHeight, alignment: .leading)
					.padding(.medium3)
					.multilineTextAlignment(.leading)
					.scrollContentBackground(.hidden) // Remove the default background to allow customization
					.background(Color.containerContentBackground)
					.roundedCorners(.bottom, strokeColor: focused ? .focusedBorderColor : .borderColor)
				}
			}
			.sheet(
				store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
				state: /AssetTransferMessage.Destinations.State.messageMode,
				action: AssetTransferMessage.Destinations.Action.messageMode,
				content: {
					MessageMode.View(store: $0)
						.presentationDetents([.medium])
						.presentationDragIndicator(.visible)
					#if os(iOS)
						.presentationBackground(.blur)
					#endif
				}
			)
		}
	}
}
