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
							.padding(.trailing, 51)
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
		}
	}
}
