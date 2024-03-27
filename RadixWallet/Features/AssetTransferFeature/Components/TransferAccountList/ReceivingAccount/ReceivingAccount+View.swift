import ComposableArchitecture
import SwiftUI

// MARK: - ReceivingAccount.View
extension ReceivingAccount {
	public typealias ViewState = State

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<ReceivingAccount>

		public init(store: StoreOf<ReceivingAccount>) {
			self.store = store
		}
	}
}

extension ReceivingAccount.View {
	public var body: some View {
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
				SmallAccountCard(
					account.name,
					identifiable: account.identifer,
					gradient: account.gradient
				) {
					removeAccountButton(viewStore)
						.foregroundColor(.app.white)
						.padding(.leading, .medium3)
				}
			} else {
				HStack {
					Button(L10n.AssetTransfer.ReceivingAccount.chooseAccountButton) {
						viewStore.send(.chooseAccountTapped)
					}
					.textStyle(.body1Header)
					Spacer()
					if viewStore.canBeRemoved {
						removeAccountButton(viewStore)
					}
				}
				.padding(.horizontal, .medium3)
				.foregroundColor(.app.gray2)
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

			Button(L10n.AssetTransfer.ReceivingAccount.addAssetsButton) {
				viewStore.send(.addAssetTapped)
			}
			.frame(height: .standardButtonHeight)
			.foregroundColor(.app.gray2)
			.textStyle(.body1StandaloneLink)
		}
		.frame(maxWidth: .infinity)
		.padding([.top, .horizontal], .medium3)
		.background(Color.containerContentBackground)
	}
}
