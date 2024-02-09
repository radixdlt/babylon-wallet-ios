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
						store.scope(state: \.receivingAccounts, action: \.child.receivingAccount),
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
			.destinations(with: store)
		}
	}
}

private extension StoreOf<TransferAccountList> {
	var destination: PresentationStoreOf<TransferAccountList.Destination> {
		func scopeState(state: State) -> PresentationState<TransferAccountList.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<TransferAccountList>) -> some View {
		let destinationStore = store.destination
		return chooseAccount(with: destinationStore)
			.addAsset(with: destinationStore)
	}

	private func chooseAccount(with destinationStore: PresentationStoreOf<TransferAccountList.Destination>) -> some View {
		sheet(store: destinationStore.scope(state: \.state.chooseAccount, action: \.chooseAccount)) {
			ChooseReceivingAccount.View(store: $0)
		}
	}

	private func addAsset(with destinationStore: PresentationStoreOf<TransferAccountList.Destination>) -> some View {
		sheet(store: destinationStore.scope(state: \.state.addAsset, action: \.addAsset)) { assetsStore in
			AssetsView.View(store: assetsStore)
				.withNavigationBar {
					assetsStore.send(.view(.closeButtonTapped))
				}
				.navigationTitle(L10n.AssetTransfer.AddAssets.navigationTitle)
				.navigationBarTitleDisplayMode(.inline)
		}
	}
}
