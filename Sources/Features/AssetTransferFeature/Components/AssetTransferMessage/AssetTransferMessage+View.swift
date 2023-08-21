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

extension ViewStore<AssetTransferMessage.State, AssetTransferMessage.ViewAction> {
	var focusedBinding: Binding<Bool> {
		binding(get: \.focused, send: ViewAction.focusChanged)
	}
}

extension AssetTransferMessage.View {
	public var body: some View {
		WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
			VStack(alignment: .leading) {
				Text(L10n.AssetTransfer.transactionMessage)
					.sectionHeading
					.textCase(.uppercase)
					.flushedLeft(padding: .medium3)

				VStack(alignment: .leading, spacing: 0) {
					HStack {
						// 	FIXME: Uncomment and implement once messageKind is implemented
						//	Button {
						//		viewStore.send(.messageKindTapped)
						//	} label: {
						//		HStack {
						//			Text(L10n.Common.public)
						//			Image(asset: AssetResource.chevronDown)
						//		}
						//	}
						Text(L10n.Common.public)
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
					.bind(viewStore.focusedBinding, to: $focused)
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
