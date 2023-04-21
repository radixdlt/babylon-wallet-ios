import FeaturePrelude
import NewConnectionFeature

extension AddLedgerFactorSource.State {
	var viewState: AddLedgerFactorSource.ViewState {
		.init(
			failedToFindAnyLinks: !isConnectedToAnyCE,
			ledgerName: ledgerName,
			isLedgerNameInputVisible: isLedgerNameInputVisible,
			sendAddLedgerRequestControlState: isConnectedToAnyCE ? .enabled : .disabled,
			viewControlState: isWaitingForResponseFromLedger ? .loading(.global(text: "Waiting for ledger response")) : .enabled
		)
	}
}

// MARK: - AddLedgerFactorSource.View
extension AddLedgerFactorSource {
	public struct ViewState: Equatable {
		public let failedToFindAnyLinks: Bool
		public let ledgerName: String
		public let isLedgerNameInputVisible: Bool
		public let sendAddLedgerRequestControlState: ControlState
		public let viewControlState: ControlState
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<AddLedgerFactorSource>

		public init(store: StoreOf<AddLedgerFactorSource>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack {
					if viewStore.failedToFindAnyLinks {
						Text("⚠️ Found no open RadixConnect connections.")

						Button("Add New P2P Link") {
							viewStore.send(.addNewP2PLinkButtonTapped)
						}
						.buttonStyle(.secondaryRectangular(shouldExpand: true))
					}

					Spacer()

					if viewStore.isLedgerNameInputVisible {
						VStack {
							nameLedgerField(with: viewStore)

							Button("Confirm name") {
								viewStore.send(.confirmNameButtonTapped)
							}
							.buttonStyle(.primaryRectangular)

							Button("Skip name") {
								viewStore.send(.skipNamingLedgerButtonTapped)
							}
							.buttonStyle(.secondaryRectangular(shouldExpand: true))
						}
					} else {
						Text("Connect the Ledger device you wanna add to a computer on which you have a Browser you have RadixConnect linked to. Unlock your Ledger and open the Radix Babylon Ledger App on your ledger. Look for a new tab in your linked Browser and follow the instructions on the screen.")

						Button("Send Add Ledger Request") {
							viewStore.send(.sendAddLedgerRequestButtonTapped)
						}
						.controlState(viewStore.sendAddLedgerRequestControlState)
						.buttonStyle(.primaryRectangular)
					}
				}
				.controlState(viewStore.viewControlState)
				.padding(.horizontal, .medium3)
				.task { @MainActor in
					await ViewStore(store.stateless).send(.view(.task)).finish()
				}
				.sheet(
					store: store.scope(
						state: \.$addNewP2PLink,
						action: { .child(.addNewP2PLink($0)) }
					),
					content: { NewConnection.View(store: $0) }
				)
			}
		}

		@ViewBuilder
		private func nameLedgerField(with viewStore: ViewStoreOf<AddLedgerFactorSource>) -> some SwiftUI.View {
			AppTextField(
				primaryHeading: "Name this Ledger",
				secondaryHeading: "e.g. 'scratch'",
				placeholder: "scratched",
				text: .init(
					get: { viewStore.ledgerName },
					set: { viewStore.send(.ledgerNameChanged($0)) }
				),
				hint: .info("Displayed when you are prompted to sign with this.")
			)
			.padding()
		}
	}
}
