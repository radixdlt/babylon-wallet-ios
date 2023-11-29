extension AccountRecoveryScanInProgress.State {
	var viewState: AccountRecoveryScanInProgress.ViewState {
		.init(
			status: status,
			kind: factorSourceIDFromHash.kind,
			olympia: scheme == .bip44,
			active: active,
			hasFoundAnyAccounts: !active.isEmpty || !inactive.isEmpty
		)
	}
}

// MARK: - AccountRecoveryScanInProgress.View
public let accRecScanBatchSizePerReq = 25
public let accRecScanBatchSize = accRecScanBatchSizePerReq * 2
public extension AccountRecoveryScanInProgress {
	struct ViewState: Equatable {
		let status: AccountRecoveryScanInProgress.State.Status
		var loadingState: ControlState {
			status == .scanningNetworkForActiveAccounts ? .loading(.global(text: "Scanning network")) : .enabled
		}

		let kind: FactorSourceKind
		let olympia: Bool
		let active: IdentifiedArrayOf<Profile.Network.Account>
		let hasFoundAnyAccounts: Bool

		var title: String {
			status == .scanComplete ? "Scan Complete" : "Scan in progress"
		}

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
				VStack {
					Text(viewStore.title)
						.textStyle(.sheetTitle)

					if viewStore.active.isEmpty {
						Text("Scanning for Accounts that have been included in at least on transaction, using:")
						Text("**\(viewStore.factorSourceDescription)**")
					} else {
						ScrollView {
							VStack(alignment: .leading, spacing: .small3) {
								ForEach(viewStore.active) { account in
									SmallAccountCard(account: account)
										.cornerRadius(.small1)
								}
							}
						}
						Text("The first \(accRecScanBatchSize) potential accounts from this signing factor were scanned.")

						Button("Tap here to scan the next \(accRecScanBatchSize)") {
							store.send(.view(.scanMore))
						}.buttonStyle(.secondaryRectangular)
					}

					Spacer(minLength: 0)
				}
				.controlState(viewStore.loadingState)
				.presentsLoadingViewOverlay()
				.padding()
				.footer {
					Button("Continue") {
						store.send(.view(.continueTapped))
					}.buttonStyle(.primaryRectangular)
				}
				.onFirstAppear {
					viewStore.send(.onFirstAppear)
				}
				.destination(store: store)
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
	func destination(store: StoreOf<AccountRecoveryScanInProgress>) -> some View {
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
