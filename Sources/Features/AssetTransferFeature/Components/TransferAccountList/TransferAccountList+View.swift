import AssetsFeature
import FeaturePrelude

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
					Text("From")
						.sectionHeading
						.textCase(.uppercase)
						.flushedLeft(padding: .medium3)

					SmallAccountCard(
						viewStore.fromAccount.displayName.rawValue,
						identifiable: .address(.account(viewStore.fromAccount.address)),
						gradient: .init(viewStore.fromAccount.appearanceID)
					)
					.cornerRadius(.small1)
				}

				Text("To")
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

				Button("Add Account", asset: AssetResource.addAccount) {
					viewStore.send(.addAccountTapped)
				}
				.textStyle(.button)
				.foregroundColor(.app.blue2)
				.flushedRight
				.padding(.top, .medium1)
			}
			.sheet(
				store: store.scope(
					state: \.$destination,
					action: { .child(.destination($0)) }
				),
				content: { destinations($0) }
			)
		}
	}

	private func destinations(_ store: StoreOf<TransferAccountList.Destinations>) -> some View {
		SwitchStore(store.relay()) {
			CaseLet(
				state: /TransferAccountList.Destinations.MainState.chooseAccount,
				action: TransferAccountList.Destinations.MainAction.chooseAccount,
				then: { ChooseReceivingAccount.View(store: $0) }
			)

			CaseLet(
				state: /TransferAccountList.Destinations.MainState.addAsset,
				action: TransferAccountList.Destinations.MainAction.addAsset,
				then: { AssetsView.View(store: $0) }
			)
		}
	}
}
