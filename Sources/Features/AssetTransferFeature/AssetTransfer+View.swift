import FeaturePrelude

extension AssetTransfer {
	public typealias ViewState = State

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<AssetTransfer>

		public init(store: StoreOf<AssetTransfer>) {
			self.store = store
		}
	}
}

extension AssetTransfer.View {
	public var body: some View {
		WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
			ScrollView {
				VStack(spacing: .medium3) {
					headerView(viewStore)
					IfLetStore(
						store.scope(state: \.message, action: { .child(.message($0)) }),
						then: {
							AssetTransferMessage.View(store: $0)
						}
					)

					TransferAccountList.View(
						store: store.scope(state: \.accounts, action: { .child(.accounts($0)) })
					)

					FixedSpacer(height: .large1)

					Button("Send Transfer Request") {
						viewStore.send(.sendTransferTapped)
					}
					.buttonStyle(.primaryRectangular)
					// .controlState(viewStore.canSendTransferRequest ? .enabled : .disabled)
				}
				.padding(.horizontal, .medium3)
				.safeAreaInset(edge: .top, alignment: .leading, spacing: 0) {
					CloseButton {
						viewStore.send(.closeButtonTapped)
					}
					.padding([.top, .leading], .medium1)
					.padding(.bottom, .medium3)
				}
			}
		}
		.scrollDismissesKeyboard(.interactively)
		.showDeveloperDisclaimerBanner()
	}

	func headerView(_ viewStore: ViewStoreOf<AssetTransfer>) -> some View {
		HStack {
			Text("Transfer")
				.textStyle(.sheetTitle)
				.flushedLeft(padding: .small1)
			Spacer()
			if viewStore.message == nil {
				Button("Add Message", asset: AssetResource.addMessage) {
					viewStore.send(.addMessageTapped)
				}
				.textStyle(.button)
				.foregroundColor(.app.blue2)
			}
		}
	}
}
