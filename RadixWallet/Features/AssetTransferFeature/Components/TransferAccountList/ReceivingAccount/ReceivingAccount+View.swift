import ComposableArchitecture
import SwiftUI

// MARK: - ReceivingAccount.View
extension ReceivingAccount {
	typealias ViewState = State

	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<ReceivingAccount>

		init(store: StoreOf<ReceivingAccount>) {
			self.store = store
		}
	}
}

extension ReceivingAccount.View {
	var body: some View {
		WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
			VStack(alignment: .leading, spacing: .zero) {
				account(viewStore)
				Divider()
					.frame(height: 1)
					.background(Color.borderColor)
				assets(viewStore)
			}
			.roundedCorners(strokeColor: .borderColor)
		}
	}

	private func removeAccountButton(_ viewStore: ViewStoreOf<ReceivingAccount>) -> some View {
		Button {
			viewStore.send(.removeTapped)
		} label: {
			Image(asset: AssetResource.close)
				.frame(.smallest)
		}
	}

	private func account(_ viewStore: ViewStoreOf<ReceivingAccount>) -> some View {
		Group {
			if let account = viewStore.recipient {
				AccountCard(kind: .display(addCornerRadius: false), account: account) {
					removeAccountButton(viewStore)
						.foregroundColor(.app.white)
						.padding(.leading, .medium3)
				}
			} else {
				HStack {
					Button {
						viewStore.send(.chooseAccountTapped)
					} label: {
						Label(L10n.AssetTransfer.ReceivingAccount.chooseAccountButton, asset: AssetResource.chooseAccount)
							.font(.app.body1Header)
							.foregroundColor(.app.blue2)
							.flushedLeft
							.padding(.vertical, .medium3)
					}
					Spacer()
					if viewStore.canBeRemoved {
						removeAccountButton(viewStore)
					}
				}
				.padding(.horizontal, .medium3)
				.foregroundColor(.secondaryText)
			}
		}
		.frame(height: .standardButtonHeight)
	}

	private func assets(_ viewStore: ViewStoreOf<ReceivingAccount>) -> some View {
		VStack(spacing: .medium3) {
			ForEachStore(
				store.scope(state: \.assets, action: { .child(.row(id: $0, child: $1)) }),
				content: {
					ResourceAsset.View(store: $0)
				}
			)

			Button {
				viewStore.send(.addAssetTapped)
			} label: {
				Text("+ " + L10n.AssetTransfer.ReceivingAccount.addAssetsButton)
					.frame(height: .standardButtonHeight)
					.frame(maxWidth: .infinity)
					.foregroundColor(.app.blue2)
					.font(.app.body1StandaloneLink)
			}
		}
		.frame(maxWidth: .infinity)
		.padding([.top, .horizontal], .medium3)
		.background(Color.containerContentBackground)
	}
}
