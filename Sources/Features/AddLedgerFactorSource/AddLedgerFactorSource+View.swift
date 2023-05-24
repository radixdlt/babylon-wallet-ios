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
			NavigationStack {
				WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
					VStack {
						Text("Add Ledger Device") // FIXME: String
							.textStyle(.sheetTitle)
							.padding(.bottom, .large1)

						Text("Let’s set up a Ledger hardware wallet device. You will be able to use it to create new Ledger-secured Accounts, or import Ledger-secured Accounts from the Radix Olympia Desktop Wallet.") // FIXME: String
							.padding(.bottom, .large1)
						Text("Connect your Ledger to a computer running a linked Radix Connector browser extension, and make sure the Radix Babylon app is running on the Ledger device.") // FIXME: String

						Spacer()

						Button(L10n.Common.continue) {
							viewStore.send(.sendAddLedgerRequestButtonTapped)
						}
						.controlState(viewStore.sendAddLedgerRequestControlState)
						.buttonStyle(.primaryRectangular)
					}
					.foregroundColor(.app.gray1)
					.padding(.horizontal, .large2)

					.confirmationDialog(
						store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
						state: /AddLedgerFactorSource.Destinations.State.closeLedgerAlreadyExistsConfirmationDialog,
						action: AddLedgerFactorSource.Destinations.Action.closeLedgerAlreadyExistsConfirmationDialog
					)
				}

//					if let model = viewStore.modelOfLedgerToName {
//						VStack {
//							nameLedgerField(with: viewStore, model: model)
//
//							Button("Confirm name") {
//								viewStore.send(.confirmNameButtonTapped)
//							}
//							.buttonStyle(.primaryRectangular)
//						}
//					} else {
//						Text("Let’s set up a Ledger hardware wallet device. You will be able to use it to create new Ledger-secured Accounts, or import Ledger-secured Accounts from the Radix Olympia Desktop Wallet.") // FIXME: String
//
//						Button("Send Add Ledger Request") {
//							viewStore.send(.sendAddLedgerRequestButtonTapped)
//						}
//						.controlState(viewStore.sendAddLedgerRequestControlState)
//						.buttonStyle(.primaryRectangular)
//					}
//				}
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

extension NameLedgerFactorSource {
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
			NavigationStack {
				WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
					VStack {
						Text("Add Ledger Device") // FIXME: String
							.textStyle(.sheetTitle)
							.padding(.bottom, .large1)

						Text("Let’s set up a Ledger hardware wallet device. You will be able to use it to create new Ledger-secured Accounts, or import Ledger-secured Accounts from the Radix Olympia Desktop Wallet.") // FIXME: String
							.padding(.bottom, .large1)
						Text("Connect your Ledger to a computer running a linked Radix Connector browser extension, and make sure the Radix Babylon app is running on the Ledger device.") // FIXME: String

						Spacer()

						Button(L10n.Common.continue) {
							viewStore.send(.sendAddLedgerRequestButtonTapped)
						}
						.controlState(viewStore.sendAddLedgerRequestControlState)
						.buttonStyle(.primaryRectangular)
					}
					.foregroundColor(.app.gray1)
					.padding(.horizontal, .large2)

					.confirmationDialog(
						store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
						state: /AddLedgerFactorSource.Destinations.State.closeLedgerAlreadyExistsConfirmationDialog,
						action: AddLedgerFactorSource.Destinations.Action.closeLedgerAlreadyExistsConfirmationDialog
					)
				}

//					if let model = viewStore.modelOfLedgerToName {
//						VStack {
//							nameLedgerField(with: viewStore, model: model)
//
//							Button("Confirm name") {
//								viewStore.send(.confirmNameButtonTapped)
//							}
//							.buttonStyle(.primaryRectangular)
//						}
//					} else {
//						Text("Let’s set up a Ledger hardware wallet device. You will be able to use it to create new Ledger-secured Accounts, or import Ledger-secured Accounts from the Radix Olympia Desktop Wallet.") // FIXME: String
//
//						Button("Send Add Ledger Request") {
//							viewStore.send(.sendAddLedgerRequestButtonTapped)
//						}
//						.controlState(viewStore.sendAddLedgerRequestControlState)
//						.buttonStyle(.primaryRectangular)
//					}
//				}
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
