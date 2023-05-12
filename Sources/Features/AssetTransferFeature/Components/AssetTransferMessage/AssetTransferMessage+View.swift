import FeaturePrelude

// MARK: - AssetTransferMessage.View
extension AssetTransferMessage {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<AssetTransferMessage>
		let focused: FocusState<FocusField?>.Binding

		public init(store: StoreOf<AssetTransferMessage>, focused: FocusState<FocusField?>.Binding) {
			self.store = store
			self.focused = focused
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
								Text("Private")
								Image(asset: AssetResource.chevronDown)
							}
						}
						.textStyle(.body1HighImportance)
						.foregroundColor(.app.gray1)

						Spacer()

						Button("", asset: AssetResource.close) {
							viewStore.send(.removeMessageTapped)
						}
					}
					.padding(.medium3)
					.overlay(
						RoundedCorners(radius: .small2, corners: [.topLeft, .topRight])
							.stroke(Color.gray, lineWidth: 1)
					)

					TextEditor(text: viewStore.binding(
						get: \.message,
						send: {
							.messageChanged($0)
						}
					)
					)
					.focused(focused, equals: .message)
					.frame(minHeight: 64, alignment: .leading)
					.fixedSize(horizontal: false, vertical: true)
					.padding(.medium3)
					.multilineTextAlignment(.leading)
					.scrollContentBackground(.hidden)
					.background(.app.gray4)
					.overlay(
						RoundedCorners(radius: .small2, corners: [.bottomLeft, .bottomRight])
							.stroke(
								focused.wrappedValue == .message ? Color.black : Color.gray,
								lineWidth: 1
							)
					)
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
