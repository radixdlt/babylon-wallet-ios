private typealias S = L10n.SecurityFactors

extension SecurityFactors.State {
	var viewState: SecurityFactors.ViewState {
		.init(
			seedPhrasesCount: seedPhrasesCount,
			ledgerWalletsCount: ledgerWalletsCount,
			isSeedPhraseRequiredToRecoverAccounts: isSeedPhraseRequiredToRecoverAccounts
		)
	}
}

// MARK: - SecurityFactors.View

public extension SecurityFactors {
	struct ViewState: Equatable {
		let seedPhrasesCount: Int?
		let ledgerWalletsCount: Int?
		let isSeedPhraseRequiredToRecoverAccounts: Bool
	}

	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<SecurityFactors>

		public init(store: StoreOf<SecurityFactors>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			content
				.setUpNavigationBar(title: S.title)
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
					ForEach(rows(viewStore: viewStore)) { kind in
						kind.build(viewStore: viewStore)
					}
				}
			}
			.background(Color.app.gray4)
			.onFirstTask { @MainActor in
				await viewStore.send(.onFirstTask).finish()
			}
		}
	}

	func rows(viewStore: ViewStoreOf<SecurityFactors>) -> [SettingsRow<SecurityFactors>] {
		[
			.header(S.subtitle),
			.model(
				title: S.SeedPhrases.title,
				subtitle: S.SeedPhrases.subtitle,
				detail: seedPhrasesDetail(viewStore),
				hints: seedPhraseHints(viewStore),
				icon: .asset(AssetResource.seedPhrases),
				action: .seedPhrasesButtonTapped
			),
			.model(
				title: S.LedgerWallet.title,
				subtitle: S.LedgerWallet.subtitle,
				detail: ledgerWalletsDetail(viewStore),
				icon: .asset(AssetResource.ledger),
				action: .ledgerWalletsButtonTapped
			),
		]
	}

	func seedPhrasesDetail(_ viewStore: ViewStoreOf<SecurityFactors>) -> String? {
		guard let count = viewStore.seedPhrasesCount else {
			return nil
		}
		return count == 1 ? S.SeedPhrases.counterSingular : S.SeedPhrases.counterPlural(count)
	}

	func seedPhraseHints(_ viewStore: ViewStoreOf<SecurityFactors>) -> [Hint.ViewState] {
		guard viewStore.isSeedPhraseRequiredToRecoverAccounts else {
			return []
		}
		return [.init(kind: .warning, text: .init(S.SeedPhrases.enterSeedPhrase))]
	}

	func ledgerWalletsDetail(_ viewStore: ViewStoreOf<SecurityFactors>) -> String? {
		guard let count = viewStore.ledgerWalletsCount else {
			return nil
		}
		return count == 1 ? S.LedgerWallet.counterSingular : S.LedgerWallet.counterPlural(count)
	}
}

// MARK: - Extensions

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
		navigationDestination(
			store: destinationStore,
			state: /SecurityFactors.Destination.State.seedPhrases,
			action: SecurityFactors.Destination.Action.seedPhrases,
			destination: { DisplayMnemonics.View(store: $0) }
		)
	}

	private func ledgerHardwareWallets(with destinationStore: PresentationStoreOf<SecurityFactors.Destination>) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /SecurityFactors.Destination.State.ledgerWallets,
			action: SecurityFactors.Destination.Action.ledgerWallets,
			destination: {
				LedgerHardwareDevices.View(store: $0)
					.background(.app.gray5)
					.navigationTitle(L10n.AccountSecuritySettings.LedgerHardwareWallets.title)
					.toolbarBackground(.visible, for: .navigationBar)
			}
		)
	}
}
