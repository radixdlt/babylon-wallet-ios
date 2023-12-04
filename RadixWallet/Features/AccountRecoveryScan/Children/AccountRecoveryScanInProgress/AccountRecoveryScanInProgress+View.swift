extension AccountRecoveryScanInProgress.State {
	var viewState: AccountRecoveryScanInProgress.ViewState {
		.init(
			status: status,
			kind: factorSourceIDFromHash.kind,
			olympia: forOlympiaAccounts,
			active: active,
			lastScanFoundNewActiveAccounts: lastScanFoundNewActiveAccounts,
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
		let lastScanFoundNewActiveAccounts: Bool
		let hasFoundAnyAccounts: Bool
		let maxIndex: Int
		var indexOfLastActive: Int {
			max(0, active.count - 1)
		}

		var isScanInProgress: Bool {
			switch status {
			case .scanComplete: false
			default: true
			}
		}

		var title: String {
			// FIXME: Strings
			status == .scanComplete ? "Scan Complete" : "Scan in progress"
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
					Text(viewStore.title)
						.textStyle(.sheetTitle)

					fixedFrameHeader(with: viewStore)

					if viewStore.active.isEmpty {
						if !viewStore.isScanInProgress {
							NoContentView("None found.") // FIXME: Strings
						}
					} else {
						ScrollView {
							ScrollViewReader { pageScroller in
								VStack(alignment: .leading, spacing: .small3) {
									ForEach(Array(zip(viewStore.active.indices, viewStore.active)), id: \.1) { index, account in
										SmallAccountCard(account: account)
											.cornerRadius(.small1)
											.id(index)
									}
								}
								.onChange(of: viewStore.maxIndex) { _ in
									let indexToScrollTo = viewStore.indexOfLastActive
									// We ALWAYS need to scroll, but we ONLY wanna scroll **with animation**
									// if we found NEW active accounts.
									if viewStore.lastScanFoundNewActiveAccounts {
										withAnimation {
											pageScroller.scrollTo(indexToScrollTo, anchor: .top)
										}
									} else {
										pageScroller.scrollTo(indexToScrollTo, anchor: .top)
									}
								}
							}
						}
					}

					Text(viewStore.isScanInProgress ? "" : "The first \(viewStore.maxIndex) potential accounts from this signing factor were scanned.")
						.frame(height: .huge3) // static height so that scroll view height is static

					Spacer(minLength: 0)
				}
				.controlState(viewStore.loadingState)
				.presentsLoadingViewOverlay()
				.padding()
				.footer {
					// FIXME: Strings
					Button("Tap here to scan the next \(batchSize)") {
						store.send(.view(.scanMore))
					}
					.buttonStyle(.alternativeRectangular)

					// FIXME: Strings
					Button("Continue") {
						store.send(.view(.continueTapped))
					}
					.buttonStyle(.primaryRectangular)
				}
				.onFirstAppear {
					viewStore.send(.onFirstAppear)
				}
				.destinations(with: store)
			}
		}

		@ViewBuilder
		func fixedFrameHeader(with viewStore: ViewStoreOf<AccountRecoveryScanInProgress>) -> some SwiftUI.View {
			VStack(alignment: .center) {
				Text(viewStore.isScanInProgress ? "Scanning for Accounts that have been included in at least on transaction, using:" : "The following Accounts were found that have been included in at least one transaction:")
					.frame(height: 50) // static height because we this text to have fixed position when switching between status
				Spacer(minLength: 0)
				if viewStore.isScanInProgress {
					// FIXME: Strings
					Text("**\(viewStore.factorSourceDescription)**")
				}
			}
			.frame(height: 80) // static height else account list "jumps" when going between scanInProgress and scanCompleted
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
