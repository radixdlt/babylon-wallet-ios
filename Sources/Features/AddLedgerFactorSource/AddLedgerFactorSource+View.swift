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
						Text(L10n.AddLedgerDevice.AddDevice.title)
							.textStyle(.sheetTitle)
							.padding(.top, .small1)
							.padding(.bottom, .large1)

						Text(L10n.AddLedgerDevice.AddDevice.body1)
							.textStyle(.body1Regular)
							.padding(.bottom, .large1)
							.padding(.horizontal, .medium3)

						Text(L10n.AddLedgerDevice.AddDevice.body2)
							.textStyle(.body1Regular)
							.padding(.horizontal, .medium3)

						Spacer()

						Button(L10n.AddLedgerDevice.AddDevice.continue) {
							viewStore.send(.sendAddLedgerRequestButtonTapped)
						}
						.controlState(viewStore.continueButtonControlState)
						.buttonStyle(.primaryRectangular)
						.padding(.bottom, .large2)
					}
					.multilineTextAlignment(.center)
					.foregroundColor(.app.gray1)
					.padding(.horizontal, .medium3)
					#if os(iOS)
						.toolbar {
							ToolbarItem(placement: .primaryAction) {
								CloseButton {
									viewStore.send(.closeButtonTapped)
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
					VStack {
						Text(L10n.AddLedgerDevice.NameLedger.title)
							.textStyle(.sheetTitle)
							.padding(.top, .small1)
							.padding(.bottom, .medium3)

						Text(L10n.AddLedgerDevice.NameLedger.body)
							.textStyle(.body1Regular)
							.padding(.bottom, .medium1)
							.multilineTextAlignment(.center)

						AppTextField(
							placeholder: L10n.AddLedgerDevice.NameLedger.namePlaceholder,
							text: Binding(
								get: { viewStore.ledgerName },
								set: { viewStore.send(.ledgerNameChanged($0)) }
							)
						)

						Spacer()
					}
					.padding(.horizontal, .medium1)
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
