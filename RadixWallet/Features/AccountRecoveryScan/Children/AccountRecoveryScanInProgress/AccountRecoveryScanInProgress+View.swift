extension AccountRecoveryScanInProgress.State {
	var viewState: AccountRecoveryScanInProgress.ViewState {
		.init(
			status: status,
			kind: factorSourceIDFromHash.kind,
			olympia: forOlympiaAccounts,
			active: active,
			hasFoundAnyAccounts: !active.isEmpty || !inactive.isEmpty,
			maxIndex: batchNumber * batchSize
		)
	}
}

// MARK: - AccountRecoveryScanInProgress.View
public let batchSize = 50
public extension AccountRecoveryScanInProgress {
	struct ViewState: Equatable {
		let status: AccountRecoveryScanInProgress.State.Status
		var loadingState: ControlState {
			// FIXME: Strings
			status == .scanningNetworkForActiveAccounts ? .loading(.global(text: "Scanning network")) : .enabled
		}

		let kind: FactorSourceKind
		let olympia: Bool
		let active: IdentifiedArrayOf<Profile.Network.Account>
		let hasFoundAnyAccounts: Bool
		let maxIndex: Int

		var buttonControlState: ControlState {
			isScanInProgress ? .disabled : .enabled
		}

		var isScanInProgress: Bool {
			switch status {
			case .scanComplete: false
			default: true
			}
		}

		// FIXME: Strings
		var factorSourceDescription: String {
			switch kind {
			case .device:
				if olympia {
					"Olympia Seed Phrase"
				} else {
					"Babylon Seed Phrase"
				}
			case .ledgerHQHardwareWallet:
				"Ledger hardware wallet device"
			default: "Factor"
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
				.presentsLoadingViewOverlay()
				.padding()
				.footer {
					// FIXME: Strings
					Button("Tap here to scan the next \(batchSize)") {
						store.send(.view(.scanMore))
					}
					.buttonStyle(.alternativeRectangular)
					.controlState(viewStore.buttonControlState)

					// FIXME: Strings
					Button("Continue") {
						store.send(.view(.continueTapped))
					}
					.buttonStyle(.primaryRectangular)
					.controlState(viewStore.buttonControlState)
				}
				.onFirstAppear {
					viewStore.send(.onFirstAppear)
				}
				.destinations(with: store)
			}
		}

		@ViewBuilder
		func scanInProgressView(with viewStore: ViewStoreOf<AccountRecoveryScanInProgress>) -> some SwiftUI.View {
			Text("Scan in progress")
				.textStyle(.sheetTitle)

			Spacer()

			Text("Scanning for Accounts that have been included in at least on transaction, using:")
			Text("**\(viewStore.factorSourceDescription)**")
		}

		@ViewBuilder
		func scanCompleteView(with viewStore: ViewStoreOf<AccountRecoveryScanInProgress>) -> some SwiftUI.View {
			ScrollView {
				VStack(alignment: .center, spacing: .medium1) {
					Text("Scan Complete")
						.textStyle(.sheetTitle)

					Text("The first \(viewStore.maxIndex) potential Accounts from this signing factor were scanned. The following Accounts had at least one transaction:")

					if viewStore.active.isEmpty {
						NoContentView("None found.") // FIXME: Strings
					} else {
						// we want less spacing between accounts then between child views of the root view.
						VStack(alignment: .leading, spacing: .small3) {
							ForEach(viewStore.active) { account in
								SmallAccountCard(account: account)
									.cornerRadius(.small1)
							}
						}
					}
				}
			}
		}
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
		sheet(
			store: destinationStore,
			state: /AccountRecoveryScanInProgress.Destination.State.derivePublicKeys,
			action: AccountRecoveryScanInProgress.Destination.Action.derivePublicKeys
		) {
			DerivePublicKeys.View(store: $0)
		}
	}
}
