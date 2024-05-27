extension SecurityFactors.State {
	var viewState: SecurityFactors.ViewState {
		.init(
			seedPhrasesCount: seedPhrasesCount,
			ledgerWalletsCount: ledgerWalletsCount,
			securityProblems: securityProblems
		)
	}
}

// MARK: - SecurityFactors.View

public extension SecurityFactors {
	struct ViewState: Equatable {
		let seedPhrasesCount: Int?
		let ledgerWalletsCount: Int?
		let securityProblems: [SecurityProblem]
	}

	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<SecurityFactors>

		public init(store: StoreOf<SecurityFactors>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			content
				.radixToolbar(title: L10n.SecurityFactors.title)
				.tint(.app.gray1)
				.foregroundColor(.app.gray1)
				.presentsLoadingViewOverlay()
				.destinations(with: store)
		}
	}
}

@MainActor
private extension SecurityFactors.View {
	var content: some View {
		WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
			ScrollView {
				VStack(spacing: .zero) {
					ForEachStatic(rows(viewStore: viewStore)) { kind in
						SettingsRow(kind: kind, store: store)
					}
				}
			}
			.background(Color.app.gray5)
			.onAppear {
				store.send(.view(.appeared))
			}
		}
	}

	func rows(viewStore: ViewStoreOf<SecurityFactors>) -> [SettingsRow<SecurityFactors>.Kind] {
		[
			.header(L10n.SecurityFactors.subtitle),
			.model(
				title: L10n.SecurityFactors.SeedPhrases.title,
				subtitle: L10n.SecurityFactors.SeedPhrases.subtitle,
				detail: viewStore.seedPhrasesDetail,
				hints: viewStore.seedPhraseHints,
				icon: .asset(AssetResource.seedPhrases),
				action: .seedPhrasesButtonTapped
			),
			.model(
				title: L10n.SecurityFactors.LedgerWallet.title,
				subtitle: L10n.SecurityFactors.LedgerWallet.subtitle,
				detail: viewStore.ledgerWalletsDetail,
				icon: .asset(AssetResource.ledger),
				action: .ledgerWalletsButtonTapped
			),
		]
	}
}

// MARK: - Extensions

private extension SecurityFactors.ViewState {
	var seedPhrasesDetail: String? {
		guard let seedPhrasesCount else {
			return nil
		}
		return seedPhrasesCount == 1 ? L10n.SecurityFactors.SeedPhrases.counterSingular : L10n.SecurityFactors.SeedPhrases.counterPlural(seedPhrasesCount)
	}

	var seedPhraseHints: [Hint.ViewState] {
		securityProblems
			.compactMap(\.securityFactors)
			.map { .init(kind: .warning, text: $0) }
	}

	var ledgerWalletsDetail: String? {
		guard let ledgerWalletsCount else {
			return nil
		}
		return ledgerWalletsCount == 1 ? L10n.SecurityFactors.LedgerWallet.counterSingular : L10n.SecurityFactors.LedgerWallet.counterPlural(ledgerWalletsCount)
	}
}

private extension StoreOf<SecurityFactors> {
	var destination: PresentationStoreOf<SecurityFactors.Destination> {
		func scopeState(state: State) -> PresentationState<SecurityFactors.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<SecurityFactors>) -> some View {
		let destinationStore = store.destination
		return seedPhrases(with: destinationStore)
			.ledgerHardwareWallets(with: destinationStore)
	}

	private func seedPhrases(with destinationStore: PresentationStoreOf<SecurityFactors.Destination>) -> some View {
		navigationDestination(store: destinationStore.scope(state: \.seedPhrases, action: \.seedPhrases)) {
			DisplayMnemonics.View(store: $0)
		}
	}

	private func ledgerHardwareWallets(with destinationStore: PresentationStoreOf<SecurityFactors.Destination>) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /SecurityFactors.Destination.State.ledgerWallets,
			action: SecurityFactors.Destination.Action.ledgerWallets,
			destination: {
				LedgerHardwareDevices.View(store: $0)
					.background(.app.gray5)
					.radixToolbar(title: L10n.AccountSecuritySettings.LedgerHardwareWallets.title)
			}
		)
	}
}
