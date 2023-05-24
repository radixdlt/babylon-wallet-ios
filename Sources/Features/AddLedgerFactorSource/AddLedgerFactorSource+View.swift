import FeaturePrelude

extension AddLedgerFactorSource.State {
	var viewState: AddLedgerFactorSource.ViewState {
		.init(
			ledgerName: ledgerName,
			modelOfLedgerToName: unnamedDeviceToAdd?.model,
			sendAddLedgerRequestControlState: isWaitingForResponseFromLedger ? .loading(.local) : .enabled
		)
	}
}

// MARK: - AddLedgerFactorSource.View
extension AddLedgerFactorSource {
	public struct ViewState: Equatable {
		public let ledgerName: String
		public let modelOfLedgerToName: P2P.LedgerHardwareWallet.Model?
		public let sendAddLedgerRequestControlState: ControlState
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
					if let model = viewStore.modelOfLedgerToName {
						VStack {
							nameLedgerField(with: viewStore, model: model)

							Button("Confirm name") {
								viewStore.send(.confirmNameButtonTapped)
							}
							.buttonStyle(.primaryRectangular)
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
				.padding(.horizontal, .medium3)
				.confirmationDialog(
					store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
					state: /AddLedgerFactorSource.Destinations.State.closeLedgerAlreadyExistsConfirmationDialog,
					action: AddLedgerFactorSource.Destinations.Action.closeLedgerAlreadyExistsConfirmationDialog
				)
			}
		}

		@ViewBuilder
		private func nameLedgerField(
			with viewStore: ViewStoreOf<AddLedgerFactorSource>,
			model: P2P.LedgerHardwareWallet.Model
		) -> some SwiftUI.View {
			VStack {
				Text("Found ledger model: '\(model.rawValue)'")
				AppTextField(
					primaryHeading: "Name your Ledger",
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
}
