import ComposableArchitecture
import SwiftUI

// MARK: - TransferAccountList.View
extension TransferAccountList {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<TransferAccountList>

		public init(store: StoreOf<TransferAccountList>) {
			self.store = store
		}
	}
}

extension TransferAccountList.View {
	public var body: some View {
		WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
			VStack(alignment: .trailing, spacing: .zero) {
				VStack(spacing: .small2) {
					Text(L10n.AssetTransfer.AccountList.fromLabel)
						.sectionHeading
						.textCase(.uppercase)
						.flushedLeft(padding: .medium3)

					SmallAccountCard(
						viewStore.fromAccount.displayName.rawValue,
						identifiable: .address(of: viewStore.fromAccount),
						gradient: .init(viewStore.fromAccount.appearanceID)
					)
					.cornerRadius(.small1)
				}

				Text(L10n.AssetTransfer.AccountList.toLabel)
					.sectionHeading
					.textCase(.uppercase)
					.flushedLeft(padding: .medium3)
					.padding(.bottom, .small2)
					.frame(height: .dottedLineHeight, alignment: .bottom)
					.background(alignment: .trailing) {
						VLine()
							.stroke(.app.gray3, style: .transfer)
							.frame(width: 1)
							.padding(.trailing, .large1)
					}

				VStack(spacing: .medium3) {
					ForEachStore(
						store.scope(state: \.receivingAccounts, action: { .child(.receivingAccount(id: $0, action: $1)) }),
						content: { ReceivingAccount.View(store: $0) }
					)
				}

				Button(L10n.AssetTransfer.AccountList.addAccountButton, asset: AssetResource.addAccount) {
					viewStore.send(.addAccountTapped)
				}
				.textStyle(.button)
				.foregroundColor(.app.blue2)
				.flushedRight
				.padding(.top, .medium1)
			}
			.sheet(store: store.destination) { destinationStore in
				destinations(destinationStore)
			}
		}
	}

	private func destinations(_ store: StoreOf<TransferAccountList.Destinations>) -> some View {
		SwitchStore(store.relay()) { state in
			switch state {
			case .chooseAccount:
				CaseLet(
					/TransferAccountList.Destinations.MainState.chooseAccount,
					action: TransferAccountList.Destinations.MainAction.chooseAccount,
					then: { ChooseReceivingAccount.View(store: $0) }
				)

			case .addAsset:
				CaseLet(
					/TransferAccountList.Destinations.MainState.addAsset,
					action: TransferAccountList.Destinations.MainAction.addAsset,
					then: { assetsStore in
						WithNavigationBar {
							assetsStore.send(.view(.closeButtonTapped))
						} content: {
							AssetsView.View(store: assetsStore)
								.navigationTitle(L10n.AssetTransfer.AddAssets.navigationTitle)
								.navigationBarTitleDisplayMode(.inline)
						}
					}
				)
			}
		}
	}
}

private extension StoreOf<TransferAccountList> {
	var destination: PresentationStoreOf<TransferAccountList.Destinations> {
		func scopeState(state: State) -> PresentationState<TransferAccountList.Destinations.State> {
			state.$destination
		}
		return scope(state: scopeState) { .child(.destination($0)) }
	}
}
