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
			status == .scanningNetworkForActiveAccounts
				? .loading(.global(text: "Scanning network")) // FIXME: Strings
				: .enabled
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
			status != .scanComplete
		}

		// FIXME: Strings
		var factorSourceDescription: String {
			switch kind {
			case .device:
				if olympia {
					"Olympia Seed Phrase" // FIXME: Strings
				} else {
					"Babylon Seed Phrase" // FIXME: Strings
				}
			case .ledgerHQHardwareWallet:
				"Ledger hardware wallet device" // FIXME: Strings
			default: "Factor" // FIXME: Strings
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
			VStack(alignment: .center, spacing: .medium1) {
				Text("Scan in progress") // FIXME: Strings
					.textStyle(.sheetTitle)

				Spacer()

				Text("Scanning for Accounts that have been included in at least on transaction, using:") // FIXME: Strings
				Text("**\(viewStore.factorSourceDescription)**") // FIXME: Strings
			}
			.padding(.vertical, .small2)
			.padding(.horizontal, .medium1)
		}

		@ViewBuilder
		func scanCompleteView(with viewStore: ViewStoreOf<AccountRecoveryScanInProgress>) -> some SwiftUI.View {
			ScrollView {
				VStack(alignment: .center, spacing: .medium1) {
					Text("Scan Complete") // FIXME: Strings
						.textStyle(.sheetTitle)

					Text("The first **\(viewStore.maxIndex)** potential Accounts from this signing factor were scanned. The following Accounts had at least one transaction:") // FIXME: Strings

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
				.padding(.vertical, .small2)
				.padding(.horizontal, .medium3)
			}
		}

		@ViewBuilder
		func footerContent(with viewStore: ViewStoreOf<AccountRecoveryScanInProgress>) -> some SwiftUI.View {
			Button("Tap here to scan the next \(batchSize)") { // FIXME: Strings
				store.send(.view(.scanMore))
			}
			.buttonStyle(.alternativeRectangular)
			.controlState(viewStore.buttonControlState)

			Button("Continue") { // FIXME: Strings
				store.send(.view(.continueTapped))
			}
			.buttonStyle(.primaryRectangular)
			.controlState(viewStore.buttonControlState)
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
