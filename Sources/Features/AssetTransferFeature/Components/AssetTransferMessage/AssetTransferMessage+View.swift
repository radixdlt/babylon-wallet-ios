import FeaturePrelude

// MARK: - AssetTransferMessage.View
extension AssetTransferMessage {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<AssetTransferMessage>
		@FocusState var isFocused: Bool

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
						Text("Private")
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
					.focused($isFocused)
					.frame(minHeight: 64, alignment: .leading)
					.fixedSize(horizontal: false, vertical: true)
					.padding(.medium3)
					.multilineTextAlignment(.leading)
					.scrollContentBackground(.hidden)
					.background(.app.gray4)
					.overlay(
						RoundedCorners(radius: .small2, corners: [.bottomLeft, .bottomRight])
							.stroke(
								isFocused ? Color.black : Color.gray,
								lineWidth: 1
							) // TODO: Change stroke color
					)
				}
			}
		}
	}
}
