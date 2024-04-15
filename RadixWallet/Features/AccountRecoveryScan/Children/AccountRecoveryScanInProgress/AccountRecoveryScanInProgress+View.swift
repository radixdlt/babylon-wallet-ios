extension AccountRecoveryScanInProgress.State {
	var viewState: AccountRecoveryScanInProgress.ViewState {
		.init(
			showToolbar: !isManualScan,
			status: status,
			kind: factorSourceIDFromHash.kind,
			olympia: forOlympiaAccounts,
			active: active,
			hasFoundAnyAccounts: !active.isEmpty || !inactive.isEmpty,
			maxIndex: batchNumber * batchSize
		)
	}

	private var isManualScan: Bool {
		switch mode {
		case .privateHD:
			false
		case .factorSourceWithID:
			true
		}
	}
}

/// The number of accounts we derive and scan on Ledger per "request".
let batchSize = 50

// MARK: - AccountRecoveryScanInProgress.View
public extension AccountRecoveryScanInProgress {
	struct ViewState: Equatable {
		let showToolbar: Bool
		let status: AccountRecoveryScanInProgress.State.Status
		let kind: FactorSourceKind
		let olympia: Bool
		let active: IdentifiedArrayOf<Profile.Network.Account>
		let hasFoundAnyAccounts: Bool
		let maxIndex: Int

		var loadingState: ControlState {
			status == .scanningNetworkForActiveAccounts
				? .loading(.global(text: L10n.AccountRecoveryScan.InProgress.scanningNetwork))
				: .enabled
		}

		var buttonControlState: ControlState {
			isScanInProgress ? .disabled : .enabled
		}

		var isScanInProgress: Bool {
			status != .scanComplete
		}

		var closeButtonControlState: ControlState {
			isScanInProgress ? .disabled : .enabled
		}

		var factorSourceDescription: String {
			switch kind {
			case .device:
				if olympia {
					L10n.AccountRecoveryScan.InProgress.factorSourceOlympiaSeedPhrase
				} else {
					L10n.AccountRecoveryScan.InProgress.factorSourceBabylonSeedPhrase
				}
			case .ledgerHQHardwareWallet:
				L10n.AccountRecoveryScan.InProgress.factorSourceLedgerHardwareDevice
			default:
				L10n.AccountRecoveryScan.InProgress.factorSourceFallback
			}
		}
	}

	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<AccountRecoveryScanInProgress>

		public init(store: StoreOf<AccountRecoveryScanInProgress>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				coreView(with: viewStore)
					.presentsLoadingViewOverlay()
					.footer {
						footerContent(with: viewStore)
					}
					.onFirstAppear {
						viewStore.send(.onFirstAppear)
					}
					.toolbar {
						if viewStore.showToolbar {
							ToolbarItem(placement: .cancellationAction) {
								CloseButton {
									store.send(.view(.closeButtonTapped))
								}
								.controlState(viewStore.closeButtonControlState)
							}
						}
					}
					.destinations(with: store)
			}
		}

		@ViewBuilder
		func coreView(with viewStore: ViewStoreOf<AccountRecoveryScanInProgress>) -> some SwiftUI.View {
			VStack(alignment: .center, spacing: .medium1) {
				if viewStore.isScanInProgress {
					scanInProgressView(with: viewStore)
				} else {
					scanCompleteView(with: viewStore)
				}
			}
			.textStyle(.body1Regular)
			.foregroundColor(.app.gray1)
			.controlState(viewStore.loadingState)
		}

		@ViewBuilder
		func scanInProgressView(with viewStore: ViewStoreOf<AccountRecoveryScanInProgress>) -> some SwiftUI.View {
			VStack(alignment: .center, spacing: 0) {
				Text(L10n.AccountRecoveryScan.InProgress.headerTitle)
					.textStyle(.sheetTitle)
					.foregroundColor(.app.gray1)
					.padding(.bottom, .medium1)

				Text(L10n.AccountRecoveryScan.InProgress.headerSubtitle)
					.textStyle(.body1Regular)
					.foregroundColor(.app.gray1)
					.padding(.bottom, .medium2)

				Text(LocalizedStringKey(viewStore.factorSourceDescription))
					.textStyle(.body1HighImportance)
					.foregroundColor(.app.gray1)

				Spacer()
			}
			.padding(.vertical, .small2)
			.padding(.horizontal, .medium1)
		}

		@ViewBuilder
		func scanCompleteView(with viewStore: ViewStoreOf<AccountRecoveryScanInProgress>) -> some SwiftUI.View {
			ScrollView {
				VStack(alignment: .center, spacing: 0) {
					Text(L10n.AccountRecoveryScan.ScanComplete.headerTitle)
						.textStyle(.sheetTitle)
						.foregroundColor(.app.gray1)
						.padding(.bottom, .medium1)

					Text(LocalizedStringKey(L10n.AccountRecoveryScan.ScanComplete.headerSubtitle(viewStore.maxIndex)))
						.multilineTextAlignment(.center)
						.textStyle(.body1Regular)
						.foregroundColor(.app.gray1)
						.padding(.bottom, .medium1)

					if viewStore.active.isEmpty {
						NoContentView(L10n.AccountRecoveryScan.ScanComplete.noAccounts)
					} else {
						VStack(alignment: .leading, spacing: .medium3) {
							ForEach(viewStore.active) { account in
								SimpleAccountCard(account: account)
							}
						}
					}
				}
				.padding(.vertical, .small2)
				.padding(.horizontal, .medium3)
			}
		}

		@ViewBuilder
		func footerContent(with viewStore: ViewStoreOf<AccountRecoveryScanInProgress>) -> some SwiftUI.View {
			Button(L10n.AccountRecoveryScan.ScanComplete.scanNextBatchButton(batchSize)) {
				store.send(.view(.scanMore))
			}
			.buttonStyle(.alternativeRectangular)
			.controlState(viewStore.buttonControlState)

			Button(L10n.AccountRecoveryScan.ScanComplete.continueButton) {
				store.send(.view(.continueTapped))
			}
			.buttonStyle(.primaryRectangular)
			.controlState(viewStore.buttonControlState)
		}
	}
}

// MARK: - SimpleAccountCard
/// A `SmallAccountCard` without `name`, and with the address centered
private struct SimpleAccountCard: View {
	let account: Profile.Network.Account

	var body: some View {
		SmallAccountCard(
			identifiable: .address(of: account),
			gradient: .init(account.appearanceID)
		) {
			Spacer(minLength: 0)
		}
		.cornerRadius(.small1)
	}
}

private extension StoreOf<AccountRecoveryScanInProgress> {
	var destination: PresentationStoreOf<AccountRecoveryScanInProgress.Destination> {
		func scopeState(state: State) -> PresentationState<AccountRecoveryScanInProgress.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<AccountRecoveryScanInProgress>) -> some View {
		let destinationStore = store.destination
		return derivePublicKeys(with: destinationStore)
	}

	private func derivePublicKeys(with destinationStore: PresentationStoreOf<AccountRecoveryScanInProgress.Destination>) -> some View {
		sheet(store: destinationStore.scope(state: \.derivePublicKeys, action: \.derivePublicKeys)) {
			DerivePublicKeys.View(store: $0)
		}
	}
}
