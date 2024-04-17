private typealias S = L10n.SecurityFactors

extension SecurityFactors.State {
	var viewState: SecurityFactors.ViewState {
		.init(seedPhrases: seedPhrases, ledgerWallets: ledgerWallets)
	}
}

// MARK: - SecurityFactors.View

public extension SecurityFactors {
	struct ViewState: Equatable {
		let seedPhrases: Int?
		let ledgerWallets: Int?
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

	func rows(viewStore: ViewStoreOf<SecurityFactors>) -> [AbstractSettingsRow<SecurityFactors>] {
		[
			.header(S.subtitle),
			.model(.init(
				title: S.SeedPhrases.title,
				subtitle: S.SeedPhrases.subtitle,
				detail: seedPhrases(viewStore: viewStore),
				icon: .asset(AssetResource.seedPhrases),
				action: .seedPhrasesButtonTapped
			)),
			.model(.init(
				title: S.LedgerWallet.title,
				subtitle: S.LedgerWallet.subtitle,
				detail: ledgerWallets(viewStore: viewStore),
				icon: .asset(AssetResource.ledger),
				action: .ledgerWalletsButtonTapped
			)),
		]
	}

	func seedPhrases(viewStore: ViewStoreOf<SecurityFactors>) -> String? {
		guard let count = viewStore.seedPhrases else {
			return nil
		}
		return count == 1 ? S.SeedPhrases.counterSingular : S.SeedPhrases.counterPlural(count)
	}

	func ledgerWallets(viewStore: ViewStoreOf<SecurityFactors>) -> String? {
		guard let count = viewStore.ledgerWallets else {
			return nil
		}
		return count == 1 ? S.LedgerWallet.counterSingular : S.LedgerWallet.counterPlural(count)
	}
}
