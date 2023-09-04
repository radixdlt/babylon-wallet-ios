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
						.padding(.top, .medium3)

					IfLetStore(
						store.scope(state: \.message, action: { .child(.message($0)) }),
						then: { AssetTransferMessage.View(store: $0) }
					)

					TransferAccountList.View(
						store: store.scope(state: \.accounts, action: { .child(.accounts($0)) })
					)

					FixedSpacer(height: .large1)

					Button(L10n.AssetTransfer.sendTransferButton) {
						viewStore.send(.sendTransferTapped)
					}
					.buttonStyle(.primaryRectangular)
					.controlState(viewStore.canSendTransferRequest ? .enabled : .disabled)
					.padding(.bottom, .medium3)
				}
				.padding(.horizontal, .medium3)
				.background {
					Color.white
						.onTapGesture {
							viewStore.send(.backgroundTapped)
						}
				}
			}
		}
		.scrollDismissesKeyboard(.interactively)
	}

	func headerView(_ viewStore: ViewStoreOf<AssetTransfer>) -> some View {
		HStack {
			Text(L10n.AssetTransfer.Header.transfer)
				.textStyle(.sheetTitle)
				.flushedLeft(padding: .small1)

			Spacer()

			if viewStore.message == nil {
				Button(L10n.AssetTransfer.Header.addMessageButton, asset: AssetResource.addMessage) {
					viewStore.send(.addMessageTapped)
				}
				.textStyle(.button)
				.foregroundColor(.app.blue2)
			}
		}
	}
}

// MARK: - AssetTransfer.SheetView
extension AssetTransfer {
	@MainActor
	public struct SheetView: SwiftUI.View {
		private let store: StoreOf<AssetTransfer>

		public init(store: StoreOf<AssetTransfer>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithNavigationBar {
				ViewStore(store).send(.view(.closeButtonTapped))
			} content: {
				View(store: store)
			}
			// FIXME: Use a proper state
			.showDeveloperDisclaimerBanner(true)
		}
	}
}
