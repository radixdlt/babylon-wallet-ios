import FeaturePrelude

extension AddLedgerFactorSource.State {
	var viewState: AddLedgerFactorSource.ViewState {
		.init(continueButtonControlState: isWaitingForResponseFromLedger ? .loading(.local) : .enabled)
	}
}

// MARK: - AddLedgerFactorSource.View
extension AddLedgerFactorSource {
	public struct ViewState: Equatable {
		public let continueButtonControlState: ControlState
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
							.padding(.top, .small1)
							.padding(.bottom, .large1)

						Text("Let’s set up a Ledger hardware wallet device. You will be able to use it to create new Ledger-secured Accounts, or import Ledger-secured Accounts from the Radix Olympia Desktop Wallet.") // FIXME: String
							.padding(.bottom, .large1)
						Text("Connect your Ledger to a computer running a linked Radix Connector browser extension, and make sure the Radix Babylon app is running on the Ledger device.") // FIXME: String

						Spacer()

						Button(L10n.Common.continue) {
							viewStore.send(.sendAddLedgerRequestButtonTapped)
						}
						.controlState(viewStore.continueButtonControlState)
						.buttonStyle(.primaryRectangular)
						.padding(.bottom, .large2)
					}
					.multilineTextAlignment(.center)
					.foregroundColor(.app.gray1)
					.padding(.horizontal, .large2)
					#if os(iOS)
						.toolbar {
							ToolbarItem(placement: .primaryAction) {
								CloseButton {
//								viewStore.send(.closeButtonTapped)
								}
							}
						}
					#endif
				}
				.destination(store: store)
			}
		}
	}
}

extension View {
	@MainActor
	fileprivate func destination(store: StoreOf<AddLedgerFactorSource>) -> some View {
		let destinationStore = store.scope(state: \.$destination, action: { .child(.destination($0)) })
		return ledgerAlreadyExistsAlert(with: destinationStore)
	}

	@MainActor
	private func ledgerAlreadyExistsAlert(with destinationStore: PresentationStoreOf<AddLedgerFactorSource.Destinations>) -> some View {
		alert(
			store: destinationStore,
			state: /AddLedgerFactorSource.Destinations.State.ledgerAlreadyExistsAlert,
			action: AddLedgerFactorSource.Destinations.Action.ledgerAlreadyExistsAlert
		)
	}

	@MainActor
	private func nameLedger(with destinationStore: PresentationStoreOf<AddLedgerFactorSource.Destinations>) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /AddLedgerFactorSource.Destinations.State.nameLedger,
			action: AddLedgerFactorSource.Destinations.Action.nameLedger,
			destination: { NameLedgerFactorSource.View(store: $0) }
		)
	}
}

extension NameLedgerFactorSource.State {
	var viewState: NameLedgerFactorSource.ViewState {
		.init(ledgerName: ledgerName, model: deviceInfo.model)
	}
}

extension NameLedgerFactorSource {
	public struct ViewState: Equatable {
		public let ledgerName: String
		public let model: P2P.LedgerHardwareWallet.Model
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<NameLedgerFactorSource>

		public init(store: StoreOf<NameLedgerFactorSource>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			NavigationStack {
				WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
					VStack {
						Text("Found ledger model: '\(viewStore.model.rawValue)'")
						AppTextField(
							primaryHeading: "Name your Ledger",
							secondaryHeading: "e.g. 'scratch'",
							placeholder: "scratched",
							text: Binding(
								get: { viewStore.ledgerName },
								set: { viewStore.send(.ledgerNameChanged($0)) }
							),
							hint: .info("Displayed when you are prompted to sign with this.")
						)
						.padding()

						Button("Confirm name") {
							viewStore.send(.confirmNameButtonTapped)
						}
						.buttonStyle(.primaryRectangular)
					}
				}
			}
		}
	}
}
