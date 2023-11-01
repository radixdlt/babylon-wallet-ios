import ComposableArchitecture
import SwiftUI
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
					VStack(spacing: 0) {
						ViewThatFits(in: .vertical) {
							InnerView(small: false)
							InnerView(small: true)
						}

						Spacer(minLength: .small1)

						Button(L10n.AddLedgerDevice.AddDevice.continue) {
							viewStore.send(.sendAddLedgerRequestButtonTapped)
						}
						.buttonStyle(.primaryRectangular)
						.controlState(viewStore.continueButtonControlState)
						.padding(.horizontal, .medium3)
						.padding(.bottom, .large2)
					}
					.toolbar {
						ToolbarItem(placement: .primaryAction) {
							CloseButton {
								viewStore.send(.closeButtonTapped)
							}
						}
					}
				}
				.destination(store: store)
			}
		}
	}

	struct InnerView: SwiftUI.View {
		let small: Bool

		var body: some SwiftUI.View {
			VStack(spacing: 0) {
				Image(asset: AssetResource.iconHardwareLedger)
					.resizable()
					.frame(small ? .veryLarge : .huge)
					.padding(.top, small ? .large3 : .huge2)
					.padding(.bottom, small ? .large2 : .huge1)

				Text(L10n.AddLedgerDevice.AddDevice.title)
					.textStyle(.sheetTitle)
					.padding(.bottom, small ? .medium3 : .large3)

				Text(L10n.AddLedgerDevice.AddDevice.body1)
					.textStyle(.body1Regular)
					.padding(.horizontal, .large3)
					.padding(.bottom, .medium2)

				Text(L10n.AddLedgerDevice.AddDevice.body2)
					.textStyle(.body1Regular)
					.padding(.horizontal, .large3)
			}
			.multilineTextAlignment(.center)
			.foregroundColor(.app.gray1)
		}
	}
}

extension View {
	@MainActor
	fileprivate func destination(store: StoreOf<AddLedgerFactorSource>) -> some View {
		let destinationStore = store.scope(state: \.$destination, action: { .child(.destination($0)) })
		return ledgerAlreadyExistsAlert(with: destinationStore)
			.nameLedger(with: destinationStore)
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

// MARK: - NameLedgerFactorSource

extension NameLedgerFactorSource.State {
	var viewState: NameLedgerFactorSource.ViewState {
		.init(
			ledgerName: ledgerName,
			model: deviceInfo.model,
			confirmButtonControlState: nameIsValid ? .enabled : .disabled
		)
	}
}

extension NameLedgerFactorSource {
	public struct ViewState: Equatable {
		public let ledgerName: String
		public let model: P2P.LedgerHardwareWallet.Model
		public let confirmButtonControlState: ControlState
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
					ScrollView(showsIndicators: false) {
						VStack(spacing: 0) {
							Text(L10n.AddLedgerDevice.NameLedger.title)
								.textStyle(.sheetTitle)
								.padding(.top, .small1)
								.padding(.horizontal, .large3)
								.padding(.bottom, .small2)

							Text(L10n.AddLedgerDevice.NameLedger.subtitle)
								.textStyle(.body1Regular)
								.multilineTextAlignment(.center)
								.padding(.horizontal, .large1)
								.padding(.bottom, .large1)

							Text(L10n.AddLedgerDevice.NameLedger.detectedType(viewStore.model.displayName))
								.textStyle(.body1Header)
								.multilineTextAlignment(.center)
								.padding(.horizontal, .large1)
								.padding(.bottom, .medium1)

							AppTextField(
								placeholder: "",
								text: Binding(
									get: { viewStore.ledgerName },
									set: { viewStore.send(.ledgerNameChanged($0)) }
								),
								hint: .info(L10n.AddLedgerDevice.NameLedger.fieldHint)
							)
							.padding(.horizontal, .medium3)
							.padding(.bottom, .small1)
						}
					}
					.foregroundColor(.app.gray1)
					.footer {
						Button(L10n.AddLedgerDevice.NameLedger.continueButtonTitle) {
							viewStore.send(.confirmNameButtonTapped)
						}
						.controlState(viewStore.confirmButtonControlState)
						.buttonStyle(.primaryRectangular)
					}
				}
			}
		}
	}
}

extension P2P.LedgerHardwareWallet.Model {
	var displayName: String {
		switch self {
		case .nanoS:
			"Ledger Nano S"
		case .nanoSPlus:
			"Ledger Nano S+"
		case .nanoX:
			"Ledger Nano X"
		}
	}
}
