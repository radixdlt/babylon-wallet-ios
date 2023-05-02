import FeaturePrelude
import NewConnectionFeature

extension AddLedgerFactorSource.State {
	var viewState: AddLedgerFactorSource.ViewState {
		.init(
			failedToFindAnyLinks: !isConnectedToAnyCE,
			ledgerName: ledgerName,
			modelOfLedgerToName: unnamedDeviceToAdd?.model,
			sendAddLedgerRequestControlState: isConnectedToAnyCE ? (isWaitingForResponseFromLedger ? .loading(.local) : .enabled) : .disabled
		)
	}
}

// MARK: - AddLedgerFactorSource.View
extension AddLedgerFactorSource {
	public struct ViewState: Equatable {
		public let failedToFindAnyLinks: Bool
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
					if viewStore.failedToFindAnyLinks {
						Text("⚠️ Found no open RadixConnect connections.")

						Button("Add New P2P Link") {
							viewStore.send(.addNewP2PLinkButtonTapped)
						}
						.buttonStyle(.secondaryRectangular(shouldExpand: true))
					}

					if let model = viewStore.modelOfLedgerToName {
						VStack {
							nameLedgerField(with: viewStore, model: model)

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
				.padding(.horizontal, .medium3)
				.task { @MainActor in
					await ViewStore(store.stateless).send(.view(.task)).finish()
				}
				.confirmationDialog(
					store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
					state: /AddLedgerFactorSource.Destinations.State.closeLedgerAlreadyExistsConfirmationDialog,
					action: AddLedgerFactorSource.Destinations.Action.closeLedgerAlreadyExistsConfirmationDialog
				)
				.sheet(
					store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
					state: /AddLedgerFactorSource.Destinations.State.addNewP2PLink,
					action: AddLedgerFactorSource.Destinations.Action.addNewP2PLink,
					content: { NewConnection.View(store: $0) }
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
