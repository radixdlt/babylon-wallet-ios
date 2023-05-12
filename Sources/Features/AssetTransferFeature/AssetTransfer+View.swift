import FeaturePrelude

// MARK: - FocusField
// extension AssetTransfer.State {
//	var viewState: AssetTransfer.ViewState {
//		.init()
//	}
// }

public enum FocusField: Hashable {
	case message
	case asset(accountContainer: ToAccountTransfer.State.ID, asset: UUID)
}

extension AssetTransfer {
	public typealias ViewState = State
//	public struct ViewState: Equatable {
//		// TODO: Add
//	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<AssetTransfer>
		@FocusState var focusedField: FocusField?

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
							AssetTransferMessage.View(store: $0, focused: $focusedField)
						}
					)

					accountsView(viewStore)

					Button("Add Account", asset: AssetResource.addAccount) {
						viewStore.send(.addAccountTapped)
					}
					.textStyle(.button)
					.foregroundColor(.app.blue2)
					.flushedRight

					FixedSpacer(height: .large1)

					Button("Send Transfer Request") {
						viewStore.send(.sendTransferTapped)
					}
					.buttonStyle(.primaryRectangular)
					.controlState(.disabled)
				}
				.padding(.horizontal, .medium3)
				.safeAreaInset(edge: .top, alignment: .leading, spacing: 0) {
					CloseButton {}
						.padding([.top, .leading], .medium1)
						.padding(.bottom, .medium3)
				}
			}
			.onTapGesture {
				focusedField = nil
			}
		}
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

	func accountsView(_ viewStore: ViewStoreOf<AssetTransfer>) -> some View {
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
				.frame(height: 64, alignment: .bottom)
				.background(alignment: .trailing) {
					VLine()
						.stroke(.app.gray3, style: .transactionReview)
						.frame(width: 1)
						.padding(.trailing, SpeechbubbleShape.triangleInset)
				}
			VStack(spacing: .medium3) {
				ForEachStore(
					store.scope(state: \.toAccounts, action: { .child(.toAccountTransfer(id: $0, action: $1)) }),
					content: { ToAccountTransfer.View(store: $0, focused: $focusedField) }
				)
			}
		}
	}
}
