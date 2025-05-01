import ComposableArchitecture
import SwiftUI

extension AssetTransfer.State {
	var viewState: AssetTransfer.ViewState {
		.init(
			canSendTransferRequest: canSendTransferRequest,
			isLoadingDepositStatus: isLoadingDepositStatus,
			message: message
		)
	}

	var showIsUsingTestnetBanner: Bool {
		!isMainnetAccount
	}
}

extension AssetTransfer {
	struct ViewState: Equatable {
		let canSendTransferRequest: Bool
		let isLoadingDepositStatus: Bool
		let message: AssetTransferMessage.State?
	}

	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<AssetTransfer>

		init(store: StoreOf<AssetTransfer>) {
			self.store = store
		}
	}
}

extension AssetTransfer.View {
	var body: some View {
		WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
			ScrollView {
				VStack(spacing: .medium3) {
					headerView(viewStore)
						.padding(.top, .medium3)

					IfLetStore(store.scope(state: \.message, action: \.child.message)) {
						AssetTransferMessage.View(store: $0)
					}

					TransferAccountList.View(
						store: store.scope(state: \.accounts, action: \.child.accounts)
					)

					FixedSpacer(height: .small2)

					Button {
						viewStore.send(.sendTransferTapped)
					} label: {
						if viewStore.isLoadingDepositStatus {
							ProgressView()
						} else {
							Text(L10n.AssetTransfer.sendTransferButton)
						}
					}
					.buttonStyle(.primaryRectangular)
					.controlState(viewStore.canSendTransferRequest ? .enabled : .disabled)
					.padding(.bottom, .medium3)
				}
				.padding(.horizontal, .medium3)
				.background {
					Color.primaryBackground
						.onTapGesture {
							viewStore.send(.backgroundTapped)
						}
				}
			}
		}
		.background(.primaryBackground)
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
	struct SheetView: SwiftUI.View {
		private let store: StoreOf<AssetTransfer>

		init(store: StoreOf<AssetTransfer>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			let bannerStore = store.scope(state: \.showIsUsingTestnetBanner, action: \.never)
			WithNavigationBar {
				store.send(.view(.closeButtonTapped))
			} content: {
				View(store: store)
			}
			.showDeveloperDisclaimerBanner(bannerStore)
		}
	}
}
