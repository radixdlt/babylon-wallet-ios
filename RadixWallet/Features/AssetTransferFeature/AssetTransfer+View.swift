import ComposableArchitecture
import SwiftUI
extension AssetTransfer.State {
	var viewState: AssetTransfer.ViewState {
		.init(
			canSendTransferRequest: canSendTransferRequest,
			message: message
		)
	}

	var showIsUsingTestnetBanner: Bool {
		!isMainnetAccount
	}
}

extension AssetTransfer {
	public struct ViewState: Equatable {
		let canSendTransferRequest: Bool
		let message: AssetTransferMessage.State?
	}

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
		WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
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
			let bannerStore = store.scope(state: \.showIsUsingTestnetBanner, action: actionless)
			WithNavigationBar {
				store.send(.view(.closeButtonTapped))
			} content: {
				View(store: store)
			}
			.showDeveloperDisclaimerBanner(bannerStore)
		}
	}
}
