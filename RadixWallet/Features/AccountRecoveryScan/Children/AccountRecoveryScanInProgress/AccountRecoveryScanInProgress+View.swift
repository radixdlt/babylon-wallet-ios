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
		case .createProfile:
			false
		case .addAccounts:
			true
		}
	}
}

/// The number of accounts we derive and scan on Ledger per "request".
let batchSize = 50

// MARK: - AccountRecoveryScanInProgress.View
extension AccountRecoveryScanInProgress {
	struct ViewState: Equatable {
		let showToolbar: Bool
		let status: AccountRecoveryScanInProgress.State.Status
		let kind: FactorSourceKind
		let olympia: Bool
		let active: IdentifiedArrayOf<Account>
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
			case .ledgerHqHardwareWallet:
				L10n.AccountRecoveryScan.InProgress.factorSourceLedgerHardwareDevice
			default:
				L10n.AccountRecoveryScan.InProgress.factorSourceFallback
			}
		}
	}

	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<AccountRecoveryScanInProgress>

		init(store: StoreOf<AccountRecoveryScanInProgress>) {
			self.store = store
		}

		var body: some SwiftUI.View {
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
			}
			.background(.primaryBackground)
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
			.foregroundColor(.primaryText)
			.controlState(viewStore.loadingState)
		}

		@ViewBuilder
		func scanInProgressView(with viewStore: ViewStoreOf<AccountRecoveryScanInProgress>) -> some SwiftUI.View {
			VStack(alignment: .center, spacing: 0) {
				Text(L10n.AccountRecoveryScan.InProgress.headerTitle)
					.textStyle(.sheetTitle)
					.foregroundColor(.primaryText)
					.padding(.bottom, .medium1)

				Text(L10n.AccountRecoveryScan.InProgress.headerSubtitle)
					.textStyle(.body1Regular)
					.foregroundColor(.primaryText)
					.padding(.bottom, .medium2)

				Text(LocalizedStringKey(viewStore.factorSourceDescription))
					.textStyle(.body1HighImportance)
					.foregroundColor(.primaryText)

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
						.foregroundColor(.primaryText)
						.padding(.bottom, .medium1)

					Text(LocalizedStringKey(L10n.AccountRecoveryScan.ScanComplete.headerSubtitle(viewStore.maxIndex)))
						.multilineTextAlignment(.center)
						.textStyle(.body1Regular)
						.foregroundColor(.primaryText)
						.padding(.bottom, .medium1)

					if viewStore.active.isEmpty {
						NoContentView(L10n.AccountRecoveryScan.ScanComplete.noAccounts)
					} else {
						VStack(alignment: .leading, spacing: .medium3) {
							ForEach(viewStore.active) { account in
								AccountCard(account: account, showName: false)
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
